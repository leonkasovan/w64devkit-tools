// w64devkit Tools: Library Installer
// A native Windows GUI application using libui-ng

/*
C:\Projects\w64devkit-tools>freebuff

To continue this session later, run:
freebuff --continue 2026-06-16T00-09-41.384Z
*/

#include "ui.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <process.h>    // _beginthreadex
#include <windows.h>    // HANDLE, CloseHandle, FindFirstFile, etc.

#include <string>
#include <vector>
#include <unordered_set>
#include <unordered_map>
#include <mutex>
#include <fstream>
#include <sstream>
#include <algorithm>

// ---- Library database ----

struct Library {
    std::string name;
    std::string version;
    std::string desc;
    std::string deps;       // comma-separated, or empty
    std::string script;
    int level;              // 0+ dependency level
};

// ---- Test database ----

struct Test {
    std::string desc;
    std::string deps;       // comma-separated library names this test needs
    std::string script;
};

// ---- Runtime-populated globals ----

static std::vector<Library> libs;
static std::vector<int> selected;           // 0/1 flags
static int NUM_LIBS = 0;

static std::vector<Test> tests;
static std::vector<int> testSelected;       // 0/1 flags
static int NUM_TESTS = 0;

static std::mutex gLock;                    // guards libs/selected/tests/testSelected across threads

// ---- UI controls ----

static uiWindow *window = nullptr;
static uiEntry *prefixEntry = nullptr;
static uiTable *libTable = nullptr;
static uiTableModel *libTableModel = nullptr;
static uiTable *testTable = nullptr;
static uiTableModel *testTableModel = nullptr;
static uiCheckbox *forceUpdateCb = nullptr;
static uiButton *installBtn = nullptr;
static uiButton *buildTestBtn = nullptr;
static uiMultilineEntry *outputPane = nullptr;

// ---- Install job (allocated on heap for background thread) ----

struct InstallJob {
    std::vector<int> order;
    int count = 0;
    char prefix[256]{};
    char iniPath[MAX_PATH]{};
    int forceUpdate = 0;
};

// Queue UI updates from worker thread via uiQueueMain
struct UiUpdate {
    char text[4096]{};
    bool done = false;
};

// ---- Script-directory scanner ----

// Extract a header field like "#name: xxx" from file content.
static std::string getField(const std::string &content, const std::string &prefix) {
    std::istringstream stream(content);
    std::string line;
    while (std::getline(stream, line)) {
        if (line.rfind(prefix, 0) == 0) {          // starts with prefix
            std::string val = line.substr(prefix.size());
            // trim leading whitespace
            size_t pos = val.find_first_not_of(" \t\r\n");
            if (pos != std::string::npos)
                val = val.substr(pos);
            else
                val.clear();
            // trim trailing whitespace
            pos = val.find_last_not_of(" \t\r\n");
            if (pos != std::string::npos)
                val = val.substr(0, pos + 1);
            return val;
        }
    }
    return "";
}

static std::vector<std::string> parseDeps(const std::string &raw) {
    if (raw.empty() || raw == "none")
        return {};
    std::vector<std::string> result;
    std::istringstream stream(raw);
    std::string token;
    while (stream >> token) {
        while (!token.empty() && (token.back() == ',' || token.back() == ';'))
            token.pop_back();
        if (!token.empty())
            result.push_back(token);
    }
    return result;
}

static const std::vector<std::string> &cachedParseDeps(const std::string &raw) {
    static std::unordered_map<std::string, std::vector<std::string>> cache;
    auto it = cache.find(raw);
    if (it != cache.end())
        return it->second;
    return cache.emplace(raw, parseDeps(raw)).first->second;
}

// Calculate dependency levels via topological sort.
static void calculateLevels() {
    std::vector<int> assigned(libs.size(), -1);
    bool changed;
    do {
        changed = false;
        for (size_t i = 0; i < libs.size(); i++) {
            if (assigned[i] >= 0) continue;
            if (libs[i].deps.empty()) {
                assigned[i] = 0;
                changed = true;
                continue;
            }
            const auto &deps = cachedParseDeps(libs[i].deps);
            int maxDep = -1;
            bool allAssigned = true;
            for (const auto &d : deps) {
                bool found = false;
                for (size_t j = 0; j < libs.size(); j++) {
                    if (libs[j].name == d) {
                        if (assigned[j] < 0) { allAssigned = false; break; }
                        if (assigned[j] > maxDep) maxDep = assigned[j];
                        found = true;
                        break;
                    }
                }
                if (!found) { allAssigned = false; break; }
            }
            if (allAssigned) {
                assigned[i] = maxDep + 1;
                changed = true;
            }
        }
    } while (changed);
    for (size_t i = 0; i < libs.size(); i++) {
        if (assigned[i] < 0) {
            std::fprintf(stderr, "warning: circular dependency detected for '%s', assigning level 0\n",
                         libs[i].name.c_str());
            assigned[i] = 0;
        }
    }
    for (size_t i = 0; i < libs.size(); i++)
        libs[i].level = assigned[i];
}

// Scan scripts/install_*.sh and populate libs[] and selected[].
static void initLibs() {
    WIN32_FIND_DATAA ffd;
    HANDLE hFind = FindFirstFileA("scripts/install_*.sh", &ffd);
    if (hFind == INVALID_HANDLE_VALUE)
        return;

    std::vector<Library> temp;
    do {
        std::string fname = ffd.cFileName;          // e.g. "install_zlib.sh"
        // extract short name: strip "install_" (8) and ".sh" (3)
        std::string name = fname.substr(8, fname.size() - 11);

        // read the whole file
        std::ifstream file(("scripts/" + fname).c_str());
        if (!file.is_open()) continue;
        std::string content((std::istreambuf_iterator<char>(file)),
                             std::istreambuf_iterator<char>());

        Library lib;
        lib.name    = getField(content, "#name:");
        lib.version = getField(content, "#version:");
        lib.desc    = getField(content, "#desc:");
        std::string depsRaw = getField(content, "#deps:");
        auto depList = parseDeps(depsRaw);
        for (size_t i = 0; i < depList.size(); i++) {
            if (i > 0) lib.deps += ", ";
            lib.deps += depList[i];
        }
        // Store absolute path to the script so bash can find it regardless of cwd
        char exePathA[MAX_PATH];
        std::string exeDir;
        if (GetModuleFileNameA(NULL, exePathA, MAX_PATH)) {
            exeDir = std::string(exePathA);
            size_t sep = exeDir.find_last_of("\\/");
            if (sep != std::string::npos)
                exeDir.resize(sep + 1);
        }
        lib.script = exeDir + "scripts/" + fname;
        // Normalize to forward slashes for bash on Windows environments.
        std::replace(lib.script.begin(), lib.script.end(), '\\', '/');
        // Ensure the script path actually exists; if not, fall back to a
        // relative scripts/<name> path (also normalized).
        if (GetFileAttributesA(lib.script.c_str()) == INVALID_FILE_ATTRIBUTES) {
            lib.script = std::string("scripts/") + fname;
            std::replace(lib.script.begin(), lib.script.end(), '\\', '/');
        }

        // fallbacks if headers are missing
        if (lib.name.empty()) lib.name = name;

        temp.push_back(lib);
    } while (FindNextFileA(hFind, &ffd));
    FindClose(hFind);

    // sort alphabetically for deterministic order
    std::sort(temp.begin(), temp.end(),
              [](const Library &a, const Library &b) { return a.name < b.name; });

    libs = std::move(temp);
    calculateLevels();
    std::sort(libs.begin(), libs.end(),
              [](const Library &a, const Library &b) {
                  if (a.level != b.level) return a.level < b.level;
                  return a.name < b.name;
              });

    NUM_LIBS = static_cast<int>(libs.size());
    selected.assign(NUM_LIBS, 0);

    // Validate that all #deps: names correspond to known libraries
    for (const auto &lib : libs) {
        auto deps = parseDeps(lib.deps);
        for (const auto &d : deps) {
            bool found = false;
            for (const auto &other : libs) {
                if (other.name == d) { found = true; break; }
            }
            if (!found) {
                std::fprintf(stderr, "warning: library '%s' depends on unknown library '%s'\n",
                             lib.name.c_str(), d.c_str());
            }
        }
    }
}

// ---- Test discovery ----

static std::vector<std::string> parseTestDeps(const std::string &raw) {
    if (raw.empty() || raw == "none")
        return {};
    std::vector<std::string> result;
    std::istringstream stream(raw);
    std::string token;
    while (stream >> token) {
        while (!token.empty() && (token.back() == ',' || token.back() == ';'))
            token.pop_back();
        if (!token.empty())
            result.push_back(token);
    }
    return result;
}

static void initTests() {
    WIN32_FIND_DATAA ffd;
    HANDLE hFind = FindFirstFileA("tests/test_*.sh", &ffd);
    if (hFind == INVALID_HANDLE_VALUE)
        return;

    std::vector<Test> temp;
    do {
        Test test;
        test.script = ffd.cFileName;          // e.g. "test_sdl2mixer.sh"

        // read the whole file to extract description and deps from headers
        std::ifstream file(("tests/" + test.script).c_str());
        if (!file.is_open()) continue;
        std::string content((std::istreambuf_iterator<char>(file)),
                             std::istreambuf_iterator<char>());

        
        test.desc  = getField(content, "#desc:");
        std::string depsRaw = getField(content, "#deps:");
        auto depList = parseDeps(depsRaw);
        for (size_t i = 0; i < depList.size(); i++) {
            if (i > 0) test.deps += ", ";
            test.deps += depList[i];
        }

        // fallback if headers are missing
        if (test.desc.empty()) test.desc = "Test for " + test.script;

        temp.push_back(test);
    } while (FindNextFileA(hFind, &ffd));
    FindClose(hFind);

    tests = std::move(temp);
    NUM_TESTS = static_cast<int>(tests.size());
    testSelected.assign(NUM_TESTS, 0);
}

// ---- Window close ----

static int onClosing(uiWindow *, void *) {
    uiQuit();
    return 1;
}

// ---- Selection helpers ----

static void selectDeps(int idx) {
    auto deps = parseDeps(libs[idx].deps);
    for (const auto &depName : deps) {
        for (int i = 0; i < NUM_LIBS; i++) {
            if (libs[i].name == depName && !selected[i]) {
                selected[i] = 1;
                if (libTableModel)
                    uiTableModelRowChanged(libTableModel, i);
                selectDeps(i);
            }
        }
    }
}

static void onSelectAll(uiButton *, void *) {
    for (int i = 0; i < NUM_LIBS; i++) {
        selected[i] = 1;
        if (libTableModel)
            uiTableModelRowChanged(libTableModel, i);
    }
}

static void onDeselectAll(uiButton *, void *) {
    for (int i = 0; i < NUM_LIBS; i++) {
        selected[i] = 0;
        if (libTableModel)
            uiTableModelRowChanged(libTableModel, i);
    }
}

// ---- Test selection helpers ----

static void onSelectAllTests(uiButton *, void *) {
    for (int i = 0; i < NUM_TESTS; i++) {
        testSelected[i] = 1;
        if (testTableModel)
            uiTableModelRowChanged(testTableModel, i);
        // also select library dependencies
        auto deps = parseTestDeps(tests[i].deps);
        for (const auto &depName : deps) {
            for (int j = 0; j < NUM_LIBS; j++) {
                if (libs[j].name == depName && !selected[j]) {
                    selected[j] = 1;
                    if (libTableModel)
                        uiTableModelRowChanged(libTableModel, j);
                }
            }
        }
    }
}

static void onDeselectAllTests(uiButton *, void *) {
    for (int i = 0; i < NUM_TESTS; i++) {
        testSelected[i] = 0;
        if (testTableModel)
            uiTableModelRowChanged(testTableModel, i);
    }
}

// ---- Table model helpers ----
static int libModelNumColumns(uiTableModelHandler *, uiTableModel *) {
    return 3;
}

static uiTableValueType libModelColumnType(uiTableModelHandler *, uiTableModel *, int column) {
    return column == 0 ? uiTableValueTypeInt : uiTableValueTypeString;
}

static int libModelNumRows(uiTableModelHandler *, uiTableModel *) {
    return NUM_LIBS;
}

static uiTableValue *libModelCellValue(uiTableModelHandler *, uiTableModel *, int row, int column) {
    if (row < 0 || row >= NUM_LIBS)
        return uiNewTableValueString("");
    if (column == 0)
        return uiNewTableValueInt(selected[row]);

    const Library &lib = libs[row];
    if (column == 2)
        return uiNewTableValueString(lib.deps.c_str());

    std::string text = lib.name;
    if (!lib.version.empty())
        text += " (" + lib.version + ")";
    if (!lib.desc.empty())
        text += " - " + lib.desc;
    return uiNewTableValueString(text.c_str());
}

static void libModelSetCellValue(uiTableModelHandler *, uiTableModel *m, int row, int column, const uiTableValue *value) {
    if (row < 0 || row >= NUM_LIBS || value == nullptr)
        return;
    if (column == 0) {
        bool checked = uiTableValueInt(value) != 0;
        if (checked && !selected[row]) {
            selected[row] = 1;
            selectDeps(row);
        } else if (!checked) {
            selected[row] = 0;
        }
        uiTableModelRowChanged(m, row);
        return;
    }
}

static uiTableModelHandler libTableModelHandler = {
    libModelNumColumns,
    libModelColumnType,
    libModelNumRows,
    libModelCellValue,
    libModelSetCellValue,
};

// ---- Test table model helpers ----

static int testModelNumColumns(uiTableModelHandler *, uiTableModel *) {
    return 3;
}

static uiTableValueType testModelColumnType(uiTableModelHandler *, uiTableModel *, int column) {
    return column == 0 ? uiTableValueTypeInt : uiTableValueTypeString;
}

static int testModelNumRows(uiTableModelHandler *, uiTableModel *) {
    return NUM_TESTS;
}

static uiTableValue *testModelCellValue(uiTableModelHandler *, uiTableModel *, int row, int column) {
    if (row < 0 || row >= NUM_TESTS)
        return uiNewTableValueString("");
    if (column == 0)
        return uiNewTableValueInt(testSelected[row]);

    const Test &test = tests[row];
    if (column == 2)
        return uiNewTableValueString(test.deps.c_str());

    std::string text = test.script;
    if (!test.desc.empty())
        text += ": " + test.desc;
    return uiNewTableValueString(text.c_str());
}

static void testModelSetCellValue(uiTableModelHandler *, uiTableModel *m, int row, int column, const uiTableValue *value) {
    if (row < 0 || row >= NUM_TESTS || value == nullptr)
        return;
    if (column == 0) {
        bool checked = uiTableValueInt(value) != 0;
        if (checked && !testSelected[row]) {
            testSelected[row] = 1;
            // auto-select library dependencies
            auto deps = parseTestDeps(tests[row].deps);
            for (const auto &depName : deps) {
                for (int i = 0; i < NUM_LIBS; i++) {
                    if (libs[i].name == depName && !selected[i]) {
                        selected[i] = 1;
                        if (libTableModel)
                            uiTableModelRowChanged(libTableModel, i);
                    }
                }
            }
        } else if (!checked) {
            testSelected[row] = 0;
        }
        uiTableModelRowChanged(m, row);
        return;
    }
}

static uiTableModelHandler testTableModelHandler = {
    testModelNumColumns,
    testModelColumnType,
    testModelNumRows,
    testModelCellValue,
    testModelSetCellValue,
};

static bool fileExistsW(const wchar_t *path) {
    return GetFileAttributesW(path) != INVALID_FILE_ATTRIBUTES;
}

static std::wstring findIconPath() {
    const wchar_t baseName[] = L"w64devkit.ico";
    if (fileExistsW(baseName))
        return std::wstring(baseName);

    wchar_t exePath[MAX_PATH];
    if (!GetModuleFileNameW(NULL, exePath, MAX_PATH))
        return std::wstring();
    std::wstring dir(exePath);
    size_t sep = dir.find_last_of(L"\\/");
    if (sep != std::wstring::npos)
        dir.resize(sep + 1);
    return dir + baseName;
}

static void setWindowIcon(uiWindow *w) {
    // First try to load an icon compiled into the executable as a resource (ID 101).
    HICON icon = LoadIcon(GetModuleHandle(NULL), MAKEINTRESOURCE(101));
    // Fallback to loading from file if resource is not present
    if (!icon) {
        std::wstring iconPath = findIconPath();
        if (!iconPath.empty())
            icon = reinterpret_cast<HICON>(LoadImageW(NULL, iconPath.c_str(), IMAGE_ICON, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE | LR_SHARED));
    }
    if (!icon)
        return;
    HWND hwnd = reinterpret_cast<HWND>(uiControlHandle(uiControl(w)));
    if (!hwnd)
        return;
    SendMessageW(hwnd, WM_SETICON, ICON_SMALL, reinterpret_cast<LPARAM>(icon));
    SendMessageW(hwnd, WM_SETICON, ICON_BIG, reinterpret_cast<LPARAM>(icon));
}

// ---- Background thread helpers ----

static void applyUiUpdate(void *data) {
    auto *upd = static_cast<UiUpdate *>(data);
    if (upd->text[0]) {
        char *current = uiMultilineEntryText(outputPane);
        size_t curLen = current ? strlen(current) : 0;
        size_t newLen = strlen(upd->text);
        if (curLen + newLen > 25000) {
            size_t keep = 20000;
            const char *tail = current;
            if (curLen > keep) {
                tail = current + (curLen - keep);
                while (tail > current && *tail != '\n') tail--;
                if (tail == current) tail = current + (curLen - keep);
            }
            std::string s(tail);
            s += "\n--- trimmed (output limit) ---\n";
            s += upd->text;
            uiMultilineEntrySetText(outputPane, s.c_str());
        } else {
            uiMultilineEntryAppend(outputPane, upd->text);
        }
        uiFreeText(current);
    }
    if (upd->done) {
        uiControlEnable(uiControl(installBtn));
        uiControlEnable(uiControl(buildTestBtn));
    }
    delete upd;
}

static void sendUpdate(const char *text, int /*progress*/, bool done) {
    auto *upd = new UiUpdate();
    if (text) {
        std::strncpy(upd->text, text, sizeof(upd->text) - 1);
    }
    upd->done = done;
    uiQueueMain(applyUiUpdate, upd);
}

static std::string toNativePath(std::string path) {
    std::replace(path.begin(), path.end(), '/', '\\');
    return path;
}

static std::string toBashPath(std::string path) {
    std::replace(path.begin(), path.end(), '\\', '/');
    return path;
}

// ---- Installed library tracking ----

static std::unordered_set<std::string> loadInstalled(const char *path, const char *prefix) {
    std::unordered_set<std::string> set;
    std::ifstream file(path);
    if (!file) return set;
    std::string target = std::string(prefix) + "=";
    std::string line;
    while (std::getline(file, line)) {
        size_t s = line.find_first_not_of(" \t\r\n");
        size_t e = line.find_last_not_of(" \t\r\n");
        if (s == std::string::npos) continue;
        line = line.substr(s, e - s + 1);
        if (line.rfind(target, 0) == 0) {
            std::istringstream stream(line.substr(target.size()));
            std::string lib;
            while (stream >> lib)
                set.insert(lib);
        }
    }
    return set;
}

static void markInstalled(const char *path, const char *prefix, const char *name) {
    std::string target = std::string(prefix) + "=";
    std::vector<std::string> lines;
    bool found = false;
    {
        std::ifstream inFile(path);
        std::string line;
        while (std::getline(inFile, line)) {
            if (!found && line.rfind(target, 0) == 0) {
                line += " ";
                line += name;
                found = true;
            }
            lines.push_back(line);
        }
    }
    if (!found)
        lines.push_back(target + name);
    std::ofstream outFile(path);
    for (const auto &l : lines)
        outFile << l << "\n";
}

// ---- Install thread ----
// Launches each script via CreateProcessW (like w64devkit.c), streaming
// stdout/stderr incrementally so the output pane stays live.

static int runScriptStreamed(const char *shell, const char *script, const char *prefix, const char *forceUpdate) {
    SECURITY_ATTRIBUTES sa{sizeof(sa), NULL, TRUE};
    HANDLE readPipe = NULL, writePipe = NULL;
    if (!CreatePipe(&readPipe, &writePipe, &sa, 0))
        return -1;
    if (!SetHandleInformation(readPipe, HANDLE_FLAG_INHERIT, 0)) {
        CloseHandle(readPipe);
        CloseHandle(writePipe);
        return -1;
    }

    // check script name if contains "test" and if so, set the working directory to "tests" instead of "scripts"
    std::wstring wdir;
    if (std::string(script).find("test") != std::string::npos) {
        wdir = L"tests";
    } else {
        wdir = L"scripts";
    }

    std::string cmdLineA = "\"" + toNativePath(shell) + "\" \"" + toBashPath(script) + "\" \"" + toBashPath(prefix) + "\" \"" + forceUpdate + "\"";
    int wlen = MultiByteToWideChar(CP_UTF8, 0, cmdLineA.c_str(), -1, NULL, 0);
    std::wstring cmdLineW(wlen, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, cmdLineA.c_str(), -1, &cmdLineW[0], wlen);

    STARTUPINFOW si{};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
    si.hStdOutput = writePipe;
    si.hStdError = writePipe;
    si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    si.wShowWindow = SW_HIDE;

    PROCESS_INFORMATION pi{};
    if (!CreateProcessW(NULL, &cmdLineW[0], NULL, NULL, TRUE, 0, NULL, wdir.c_str(), &si, &pi)) {
        DWORD err = GetLastError();
        CloseHandle(writePipe);
        CloseHandle(readPipe);
        return static_cast<int>(err);
    }

    CloseHandle(writePipe);

    char buf[4096];
    DWORD n;
    while (ReadFile(readPipe, buf, sizeof(buf) - 1, &n, NULL) && n > 0) {
        buf[n] = '\0';
        sendUpdate(buf, -1, false);
    }

    CloseHandle(readPipe);
    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD exitCode = 0;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return static_cast<int>(exitCode);
}

static unsigned int __stdcall installThread(void *data) {
    auto *job = static_cast<InstallJob *>(data);

    // Prepend the toolchain bin dir to PATH so scripts find gcc, grep, etc.
    {
        std::string path = std::string(job->prefix) + "/bin";
        const char *oldPath = getenv("PATH");
        if (oldPath && oldPath[0]) {
            path += ";";
            path += oldPath;
        }
        SetEnvironmentVariableA("PATH", path.c_str());
    }

    for (int i = 0; i < job->count; i++) {
        int libIdx = job->order[i];

        std::string libName, libVersion, libScript;
        {
            std::lock_guard<std::mutex> lock(gLock);
            libName    = libs[libIdx].name;
            libVersion = libs[libIdx].version;
            libScript  = libs[libIdx].script;
        }

        char msg[4096];
        std::snprintf(msg, sizeof(msg), ">>> Installing %s (%s)...\n",
                      libName.c_str(), libVersion.c_str());
        sendUpdate(msg, -1, false);

        std::string shell = std::string(job->prefix);
        if (!shell.empty() && shell.back() != '/' && shell.back() != '\\')
            shell += "/bin/bash.exe";
        else
            shell += "bin/bash.exe";

        const char *forceStr = job->forceUpdate ? "true" : "false";
        int rc = runScriptStreamed(shell.c_str(), libScript.c_str(), job->prefix, forceStr);
        if (rc < 0) {
            std::snprintf(msg, sizeof(msg), "!!! Failed to start install process (error %d)\n", rc);
            sendUpdate(msg, -1, true);
            delete job;
            return 1;
        }
        if (rc != 0) {
            std::snprintf(msg, sizeof(msg), "!!! %s FAILED (exit code %d)\n",
                          libName.c_str(), rc);
            sendUpdate(msg, -1, true);
            delete job;
            return 1;
        }

        markInstalled(job->iniPath, job->prefix, libName.c_str());

        std::snprintf(msg, sizeof(msg), "<<< %s done\n", libName.c_str());
        sendUpdate(msg, -1, false);
    }

    sendUpdate("\n=== All selected libraries installed successfully ===\n", -1, true);
    delete job;
    return 0;
}

// ---- Build test thread ----
// Runs test scripts (scripts/test_*.sh) similar to installThread

static unsigned int __stdcall buildTestThread(void *data) {
    auto *job = static_cast<InstallJob *>(data);  // reuse InstallJob struct

    // Prepend the toolchain bin dir to PATH so scripts find gcc, pkg-config, etc.
    {
        std::string path = std::string(job->prefix) + "/bin";
        const char *oldPath = getenv("PATH");
        if (oldPath && oldPath[0]) {
            path += ";";
            path += oldPath;
        }
        SetEnvironmentVariableA("PATH", path.c_str());
    }

    for (int i = 0; i < job->count; i++) {
        int testIdx = job->order[i];

        std::string testScript;
        {
            std::lock_guard<std::mutex> lock(gLock);
            testScript = tests[testIdx].script;
        }

        char msg[4096];
        std::snprintf(msg, sizeof(msg), ">>> Building %s...\n", testScript.c_str());
        sendUpdate(msg, -1, false);

        std::string shell = std::string(job->prefix);
        if (!shell.empty() && shell.back() != '/' && shell.back() != '\\')
            shell += "/bin/bash.exe";
        else
            shell += "bin/bash.exe";

        const char *forceStr = "false";  // not used for tests
        int rc = runScriptStreamed(shell.c_str(), testScript.c_str(), job->prefix, forceStr);
        if (rc < 0) {
            std::snprintf(msg, sizeof(msg), "!!! Failed to start build process (error %d)\n", rc);
            sendUpdate(msg, -1, true);
            delete job;
            return 1;
        }
        if (rc != 0) {
            std::snprintf(msg, sizeof(msg), "!!! %s FAILED (exit code %d)\n", testScript.c_str(), rc);
            sendUpdate(msg, -1, true);
            delete job;
            return 1;
        }

        std::snprintf(msg, sizeof(msg), "<<< %s built successfully\n", testScript.c_str());
        sendUpdate(msg, -1, false);
    }

    sendUpdate("\n=== All selected tests built successfully ===\n", -1, true);
    delete job;
    return 0;
}

// ---- Install button handler ----

static bool isUnsafePrefix(const char *s) {
    return s && (std::strpbrk(s, "\"$`&|;<>") || std::strchr(s, '\n') || std::strchr(s, '\r'));
}

static void onInstall(uiButton *, void *) {
    char *prefix = uiEntryText(prefixEntry);
    if (isUnsafePrefix(prefix)) {
        uiMultilineEntryAppend(outputPane, "Error: install prefix contains invalid characters.\n");
        uiFreeText(prefix);
        return;
    }

    auto *job = new InstallJob();

    std::strncpy(job->prefix, prefix ? prefix : "C:/w64devkit", sizeof(job->prefix) - 1);
    job->prefix[sizeof(job->prefix) - 1] = '\0';
    uiFreeText(prefix);

    // Build ini path in the res/ folder alongside the executable
    {
        char exePath[MAX_PATH];
        DWORD len = GetModuleFileNameA(NULL, exePath, MAX_PATH);
        if (len > 0 && len < MAX_PATH) {
            std::string dir(exePath);
            size_t sep = dir.find_last_of("\\/");
            if (sep != std::string::npos) {
                dir.resize(sep + 1);
                dir += "res\\installed.ini";
                std::strncpy(job->iniPath, dir.c_str(), sizeof(job->iniPath) - 1);
            }
        }
        if (!job->iniPath[0])
            std::strncpy(job->iniPath, "res/installed.ini", sizeof(job->iniPath) - 1);
    }

    job->forceUpdate = uiCheckboxChecked(forceUpdateCb) != 0 ? 1 : 0;

    // Clear the output pane
    uiMultilineEntrySetText(outputPane, "");

    // Load installed set and skip already-installed libraries
    bool forceUpdate = job->forceUpdate != 0;
    auto installed = forceUpdate ? std::unordered_set<std::string>() : loadInstalled(job->iniPath, job->prefix);

    int maxLevel = 0;
    for (int i = 0; i < NUM_LIBS; i++)
        if (libs[i].level > maxLevel) maxLevel = libs[i].level;

    job->order.resize(NUM_LIBS);
    int skipped = 0;
    for (int level = 0; level <= maxLevel; level++) {
        for (int i = 0; i < NUM_LIBS; i++) {
            if (selected[i] && libs[i].level == level) {
                if (installed.find(libs[i].name) != installed.end()) {
                    skipped++;
                    char msg[256];
                    std::snprintf(msg, sizeof(msg), "--- %s already installed, skipping\n",
                                  libs[i].name.c_str());
                    uiMultilineEntryAppend(outputPane, msg);
                } else {
                    job->order[job->count++] = i;
                }
            }
        }
    }

    if (job->count == 0) {
        if (skipped > 0)
            uiMultilineEntryAppend(outputPane, "All selected libraries already installed.\n");
        else
            uiMultilineEntryAppend(outputPane, "No libraries selected.\n");
        delete job;
        return;
    }

    char header[256];
    std::snprintf(header, sizeof(header), "=== Installing %d library%s%s%s ===\n",
                  job->count, job->count > 1 ? "s" : "",
                  forceUpdate ? " (force update)" : "",
                  skipped > 0 ? " (skipping already installed)" : "");
    uiMultilineEntryAppend(outputPane, header);
    uiControlDisable(uiControl(installBtn));

    // Spawn a background thread so the UI stays responsive
    HANDLE hThread = reinterpret_cast<HANDLE>(
        _beginthreadex(nullptr, 0, installThread, job, 0, nullptr));
    if (!hThread) {
        delete job;
        uiMultilineEntryAppend(outputPane, "Error: failed to create install thread.\n");
        uiControlEnable(uiControl(installBtn));
    } else {
        CloseHandle(hThread);
    }
}

// ---- Build test button handler ----

static void onBuildTests(uiButton *, void *) {
    char *prefix = uiEntryText(prefixEntry);
    if (isUnsafePrefix(prefix)) {
        uiMultilineEntryAppend(outputPane, "Error: install prefix contains invalid characters.\n");
        uiFreeText(prefix);
        return;
    }

    auto *job = new InstallJob();  // reuse InstallJob struct

    std::strncpy(job->prefix, prefix ? prefix : "C:/w64devkit", sizeof(job->prefix) - 1);
    job->prefix[sizeof(job->prefix) - 1] = '\0';
    uiFreeText(prefix);

    // Build ini path in the res/ folder alongside the executable
    {
        char exePath[MAX_PATH];
        DWORD len = GetModuleFileNameA(NULL, exePath, MAX_PATH);
        if (len > 0 && len < MAX_PATH) {
            std::string dir(exePath);
            size_t sep = dir.find_last_of("\\/");
            if (sep != std::string::npos) {
                dir.resize(sep + 1);
                dir += "res\\installed.ini";
                std::strncpy(job->iniPath, dir.c_str(), sizeof(job->iniPath) - 1);
            }
        }
        if (!job->iniPath[0])
            std::strncpy(job->iniPath, "res/installed.ini", sizeof(job->iniPath) - 1);
    }

    job->forceUpdate = 0;  // not used for tests

    // Clear the output pane
    uiMultilineEntrySetText(outputPane, "");

    // Build the list of selected tests
    job->order.resize(NUM_TESTS);
    for (int i = 0; i < NUM_TESTS; i++) {
        if (testSelected[i]) {
            job->order[job->count++] = i;
        }
    }

    if (job->count == 0) {
        uiMultilineEntryAppend(outputPane, "No tests selected.\n");
        delete job;
        return;
    }

    char header[256];
    std::snprintf(header, sizeof(header), "=== Building %d test%s ===\n",
                  job->count, job->count > 1 ? "s" : "");
    uiMultilineEntryAppend(outputPane, header);
    uiControlDisable(uiControl(buildTestBtn));

    // Spawn a background thread so the UI stays responsive
    HANDLE hThread = reinterpret_cast<HANDLE>(
        _beginthreadex(nullptr, 0, buildTestThread, job, 0, nullptr));
    if (!hThread) {
        delete job;
        uiMultilineEntryAppend(outputPane, "Error: failed to create build thread.\n");
        uiControlEnable(uiControl(buildTestBtn));
    } else {
        CloseHandle(hThread);
    }
}

// ---- Entry point ----

int main() {
    uiInitOptions o{};
    o.Size = sizeof(uiInitOptions);

    const char *err = uiInit(&o);
    if (err) {
        std::fprintf(stderr, "Error initializing libui: %s\n", err);
        uiFreeInitError(err);
        return 1;
    }

    // Dynamically discover libraries from scripts/ directory
    initLibs();
    // Dynamically discover tests from tests/ directory
    initTests();

    window = uiNewWindow("w64devkit Tools", 900, 700, 0);
    uiWindowSetMargined(window, 1);

    auto *vbox = uiNewVerticalBox();
    uiBoxSetPadded(vbox, 1);
    uiWindowSetChild(window, uiControl(vbox));

    // Prefix row (shared across tabs)
    auto *hbox = uiNewHorizontalBox();
    uiBoxSetPadded(hbox, 1);
    uiBoxAppend(vbox, uiControl(hbox), 0);

    uiBoxAppend(hbox, uiControl(uiNewLabel("Install prefix:")), 0);
    prefixEntry = uiNewEntry();
    uiEntrySetText(prefixEntry, "C:/w64devkit");
    uiBoxAppend(hbox, uiControl(prefixEntry), 1);

    uiBoxAppend(vbox, uiControl(uiNewHorizontalSeparator()), 0);

    // Tab control
    auto *tab = uiNewTab();
    uiBoxAppend(vbox, uiControl(tab), 1);

    // ===== INSTALL TAB =====
    auto *installVBox = uiNewVerticalBox();
    uiBoxSetPadded(installVBox, 1);
    uiTabAppend(tab, "Install", uiControl(installVBox));

    auto *libGroup = uiNewGroup("Libraries");
    uiBoxAppend(installVBox, uiControl(libGroup), 1);

    uiTableParams params{};
    params.Model = uiNewTableModel(&libTableModelHandler);
    libTableModel = params.Model;
    libTable = uiNewTable(&params);
    uiTableHeaderSetVisible(libTable, 1);
    uiTableAppendCheckboxColumn(libTable, "#", 0, uiTableModelColumnAlwaysEditable);
    uiTableAppendTextColumn(libTable, "Description", 1, uiTableModelColumnNeverEditable, nullptr);
    uiTableAppendTextColumn(libTable, "Dependencies", 2, uiTableModelColumnNeverEditable, nullptr);

    uiGroupSetChild(libGroup, uiControl(libTable));

    uiTableColumnSetWidth(libTable, 0, 20);
    uiTableColumnSetWidth(libTable, 1, 400);
    uiTableColumnSetWidth(libTable, 2, 160);

    // Install tab button row
    auto *installBtnBox = uiNewHorizontalBox();
    uiBoxSetPadded(installBtnBox, 1);
    uiBoxAppend(installVBox, uiControl(installBtnBox), 0);

    auto *selectAllBtn = uiNewButton(" Select All ");
    uiButtonOnClicked(selectAllBtn, onSelectAll, nullptr);
    uiBoxAppend(installBtnBox, uiControl(selectAllBtn), 0);

    auto *deselectAllBtn = uiNewButton(" Deselect All ");
    uiButtonOnClicked(deselectAllBtn, onDeselectAll, nullptr);
    uiBoxAppend(installBtnBox, uiControl(deselectAllBtn), 0);

    installBtn = uiNewButton(" Install Selected ");
    uiButtonOnClicked(installBtn, onInstall, nullptr);
    uiBoxAppend(installBtnBox, uiControl(installBtn), 0);

    forceUpdateCb = uiNewCheckbox("Force Update");
    uiBoxAppend(installBtnBox, uiControl(forceUpdateCb), 0);

    // ===== TEST TAB =====
    auto *testVBox = uiNewVerticalBox();
    uiBoxSetPadded(testVBox, 1);
    uiTabAppend(tab, "Test", uiControl(testVBox));

    auto *testGroup = uiNewGroup("Tests");
    uiBoxAppend(testVBox, uiControl(testGroup), 1);

    uiTableParams testParams{};
    testParams.Model = uiNewTableModel(&testTableModelHandler);
    testTableModel = testParams.Model;
    testTable = uiNewTable(&testParams);
    uiTableHeaderSetVisible(testTable, 1);
    uiTableAppendCheckboxColumn(testTable, "#", 0, uiTableModelColumnAlwaysEditable);
    uiTableAppendTextColumn(testTable, "Description", 1, uiTableModelColumnNeverEditable, nullptr);
    uiTableAppendTextColumn(testTable, "Dependencies", 2, uiTableModelColumnNeverEditable, nullptr);

    uiGroupSetChild(testGroup, uiControl(testTable));

    uiTableColumnSetWidth(testTable, 0, 20);
    uiTableColumnSetWidth(testTable, 1, 400);
    uiTableColumnSetWidth(testTable, 2, 160);

    // Test tab button row
    auto *testBtnBox = uiNewHorizontalBox();
    uiBoxSetPadded(testBtnBox, 1);
    uiBoxAppend(testVBox, uiControl(testBtnBox), 0);

    auto *selectAllTestsBtn = uiNewButton(" Select All ");
    uiButtonOnClicked(selectAllTestsBtn, onSelectAllTests, nullptr);
    uiBoxAppend(testBtnBox, uiControl(selectAllTestsBtn), 0);

    auto *deselectAllTestsBtn = uiNewButton(" Deselect All ");
    uiButtonOnClicked(deselectAllTestsBtn, onDeselectAllTests, nullptr);
    uiBoxAppend(testBtnBox, uiControl(deselectAllTestsBtn), 0);

    buildTestBtn = uiNewButton(" Build Selected ");
    uiButtonOnClicked(buildTestBtn, onBuildTests, nullptr);
    uiBoxAppend(testBtnBox, uiControl(buildTestBtn), 0);

    // Output (shared, below tabs)
    uiBoxAppend(vbox, uiControl(uiNewLabel("Output:")), 0);
    outputPane = uiNewMultilineEntry();
    uiMultilineEntrySetReadOnly(outputPane, 1);
    uiBoxAppend(vbox, uiControl(outputPane), 1);

    uiWindowOnClosing(window, onClosing, nullptr);
    uiControlShow(uiControl(window));
    setWindowIcon(window);
    uiMain();
    if (libTableModel) {
        uiFreeTableModel(libTableModel);
        libTableModel = nullptr;
    }
    if (testTableModel) {
        uiFreeTableModel(testTableModel);
        testTableModel = nullptr;
    }
    uiUninit();
    return 0;
}

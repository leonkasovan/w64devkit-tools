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

// ---- Runtime-populated globals ----

static std::vector<Library> libs;
static std::vector<int> selected;           // 0/1 flags
static int NUM_LIBS = 0;

// ---- UI controls ----

static uiWindow *window = nullptr;
static uiEntry *prefixEntry = nullptr;
static uiTable *libTable = nullptr;
static uiTableModel *libTableModel = nullptr;
static uiButton *installBtn = nullptr;
static uiMultilineEntry *outputPane = nullptr;

// ---- Install job (allocated on heap for background thread) ----

struct InstallJob {
    std::vector<int> order;
    int count = 0;
    char prefix[256]{};
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
        // strip trailing comma/semicolon if attached to a token
        while (!token.empty() && (token.back() == ',' || token.back() == ';'))
            token.pop_back();
        if (!token.empty())
            result.push_back(token);
    }
    return result;
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
            // parse the dep list
            auto deps = parseDeps(libs[i].deps);
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
    // any unassigned (circular) get level 0
    for (size_t i = 0; i < libs.size(); i++)
        if (assigned[i] < 0) assigned[i] = 0;
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

static void onLibRowClicked(uiTable *t, int row, void *data) {
    (void)t; (void)data;
    if (row < 0 || row >= NUM_LIBS) return;
    if (!selected[row]) {
        selected[row] = 1;
        selectDeps(row);
    } else {
        selected[row] = 0;
    }
    if (libTableModel)
        uiTableModelRowChanged(libTableModel, row);
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
    // If the text column is edited, store the text into the library's
    // description. The cell text is "name (version) - desc", so we keep
    // the library name/version and replace only the description.
    if (column == 1) {
        const char *s = uiTableValueString(value);
        if (!s) return;
        // Try to preserve name and version; if parsing fails, replace desc entirely.
        Library &lib = libs[row];
        std::string edited(s);
        // If the edited text starts with the library name, try to extract a
        // trailing description after a ' - ' separator.
        size_t pos = edited.find(" - ");
        if (pos != std::string::npos) {
            // keep left part (name/version) intact, use right part as desc
            std::string left = edited.substr(0, pos);
            std::string right = edited.substr(pos + 3);
            // If left starts with lib.name, don't change name/version; update desc
            if (left.rfind(lib.name, 0) == 0) {
                lib.desc = right;
            } else {
                // Otherwise, store entire edited text as description
                lib.desc = edited;
            }
        } else {
            // No separator: store entire edited text as description
            lib.desc = edited;
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
        uiMultilineEntryAppend(outputPane, upd->text);
    }
    if (upd->done) {
        uiControlEnable(uiControl(installBtn));
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

// ---- Install thread ----
// Launches each script via CreateProcessW (like w64devkit.c), streaming
// stdout/stderr incrementally so the output pane stays live.

static int runScriptStreamed(const char *shell, const char *script, const char *prefix) {
    SECURITY_ATTRIBUTES sa{sizeof(sa), NULL, TRUE};
    HANDLE readPipe = NULL, writePipe = NULL;
    if (!CreatePipe(&readPipe, &writePipe, &sa, 0))
        return -1;
    if (!SetHandleInformation(readPipe, HANDLE_FLAG_INHERIT, 0)) {
        CloseHandle(readPipe);
        CloseHandle(writePipe);
        return -1;
    }

    // Convert to wide strings for CreateProcessW (w64devkit.c style)
    std::wstring wdir = L"scripts";

    std::string cmdLineA = "\"" + toNativePath(shell) + "\" \"" + toBashPath(script) + "\" \"" + toBashPath(prefix) + "\"";
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

    for (int i = 0; i < job->count; i++) {
        int libIdx = job->order[i];

        char msg[4096];
        std::snprintf(msg, sizeof(msg), ">>> Installing %s (%s)...\n",
                      libs[libIdx].name.c_str(), libs[libIdx].version.c_str());
        sendUpdate(msg, -1, false);

        std::string shell = std::string(job->prefix);
        if (!shell.empty() && shell.back() != '/' && shell.back() != '\\')
            shell += "/bin/bash.exe";
        else
            shell += "bin/bash.exe";

        int rc = runScriptStreamed(shell.c_str(), libs[libIdx].script.c_str(), job->prefix);
        if (rc < 0) {
            std::snprintf(msg, sizeof(msg), "!!! Failed to start install process (error %d)\n", rc);
            sendUpdate(msg, -1, true);
            delete job;
            return 1;
        }
        if (rc != 0) {
            std::snprintf(msg, sizeof(msg), "!!! %s FAILED (exit code %d)\n",
                          libs[libIdx].name.c_str(), rc);
            sendUpdate(msg, -1, true);
            delete job;
            return 1;
        }

        std::snprintf(msg, sizeof(msg), "<<< %s done\n", libs[libIdx].name.c_str());
        sendUpdate(msg, -1, false);
    }

    sendUpdate("\n=== All selected libraries installed successfully ===\n", -1, true);
    delete job;
    return 0;
}

// ---- Install button handler ----

static void onInstall(uiButton *, void *) {
    auto *job = new InstallJob();

    const char *prefix = uiEntryText(prefixEntry);
    std::strncpy(job->prefix, prefix ? prefix : "C:/w64devkit", sizeof(job->prefix) - 1);
    job->prefix[sizeof(job->prefix) - 1] = '\0';

    // Find max level
    int maxLevel = 0;
    for (int i = 0; i < NUM_LIBS; i++)
        if (libs[i].level > maxLevel) maxLevel = libs[i].level;

    job->order.resize(NUM_LIBS);
    for (int level = 0; level <= maxLevel; level++) {
        for (int i = 0; i < NUM_LIBS; i++) {
            if (selected[i] && libs[i].level == level) {
                job->order[job->count++] = i;
            }
        }
    }

    if (job->count == 0) {
        uiMultilineEntryAppend(outputPane, "No libraries selected.\n");
        delete job;
        return;
    }

    uiMultilineEntrySetText(outputPane, "");
    uiMultilineEntryAppend(outputPane, "=== Starting installation ===\n");
    uiControlDisable(uiControl(installBtn));

    // Spawn a background thread so the UI stays responsive
    HANDLE hThread = reinterpret_cast<HANDLE>(
        _beginthreadex(nullptr, 0, installThread, job, 0, nullptr));
    if (hThread) {
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

    window = uiNewWindow("w64devkit Tools", 800, 600, 0);
    uiWindowSetMargined(window, 1);

    auto *vbox = uiNewVerticalBox();
    uiBoxSetPadded(vbox, 1);
    uiWindowSetChild(window, uiControl(vbox));

    // Prefix row
    auto *hbox = uiNewHorizontalBox();
    uiBoxSetPadded(hbox, 1);
    uiBoxAppend(vbox, uiControl(hbox), 0);

    uiBoxAppend(hbox, uiControl(uiNewLabel("Install prefix:")), 0);
    prefixEntry = uiNewEntry();
    uiEntrySetText(prefixEntry, "C:/x86devkit");
    uiBoxAppend(hbox, uiControl(prefixEntry), 1);

    uiBoxAppend(vbox, uiControl(uiNewHorizontalSeparator()), 0);

    // Library selection table
    auto *libGroup = uiNewGroup("Libraries");
    uiBoxAppend(vbox, uiControl(libGroup), 1);

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

    // Allow clicking a row to toggle the checkbox.
    uiTableOnRowClicked(libTable, onLibRowClicked, nullptr);

    // Button row
    auto *btnBox = uiNewHorizontalBox();
    uiBoxSetPadded(btnBox, 1);
    uiBoxAppend(vbox, uiControl(btnBox), 0);

    auto *selectAllBtn = uiNewButton(" Select All ");
    uiButtonOnClicked(selectAllBtn, onSelectAll, nullptr);
    uiBoxAppend(btnBox, uiControl(selectAllBtn), 0);

    auto *deselectAllBtn = uiNewButton(" Deselect All ");
    uiButtonOnClicked(deselectAllBtn, onDeselectAll, nullptr);
    uiBoxAppend(btnBox, uiControl(deselectAllBtn), 0);

    installBtn = uiNewButton(" Install Selected ");
    uiButtonOnClicked(installBtn, onInstall, nullptr);
    uiBoxAppend(btnBox, uiControl(installBtn), 0);

    // Output
    uiBoxAppend(vbox, uiControl(uiNewLabel("Output:")), 0);
    outputPane = uiNewMultilineEntry();
    uiMultilineEntrySetReadOnly(outputPane, 1);
    uiBoxAppend(vbox, uiControl(outputPane), 1);

    uiWindowOnClosing(window, onClosing, nullptr);
    uiControlShow(uiControl(window));
    setWindowIcon(window);
    uiMain();
    uiUninit();
    return 0;
}

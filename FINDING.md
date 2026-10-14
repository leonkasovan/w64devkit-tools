# Project review findings and implementation handoff

Review date: 2026-10-14.

This document records eight actionable findings and one documentation correction from a review of the current working tree. It is an implementation handoff: fix the causes, preserve existing behavior where specified, and verify the acceptance criteria. The findings have not been fixed by this report.

## Scope, evidence, and constraints

- Reviewed `Makefile`, `main.cpp`, `README.md`, shared installer logic, installer/test scripts, resources, and relevant bundled libui queue code.
- Findings refer to the working tree, including pre-existing staged, unstaged, and untracked changes. Preserve those changes; do not reset, overwrite, or revert unrelated work.
- Line references describe the reviewed version and will move during implementation. Use the named functions and rules to locate code.
- This is a Windows-only native GUI application using bundled libui-ng. Use the Windows w64devkit toolchain; do not attempt to substitute a Linux GUI backend.
- Keep the application statically linked. Preserve release/debug executable names, the default prefix `C:/w64devkit`, streaming output, force-update behavior, and per-prefix installed tracking.
- Installer scripts must retain `#deps:`, `#desc:`, `#version:`, and `#name:` headers and source `scripts/common.sh`. Keep shared argument parsing and skip logic in that file.
- Follow the current `AGENTS.md`; its contents take precedence over assumptions in this report.

Validation actually performed during review:

1. C++ syntax check with the available Windows compiler:
   `g++ -std=c++17 -D_UI_STATIC -Ilibui-ng -Wall -Wextra -fsyntax-only main.cpp` — passed.
2. `sh -n` on every `scripts/*.sh` and `tests/*.sh` — passed.
3. Checked required installer metadata and dependency names against discovered library names — no missing required headers or unknown installer dependencies found.
4. `make -n config=Debug` with existing build artifacts — emitted only a link command using `build/main.o`, `build/libui.a`, and `build/resources.o`; no compilation commands.

No full build, GUI execution, or actual library installation was performed. Runtime consequences below are inferred from source unless explicitly identified as observed. Shell syntax checks do not establish installer correctness or download availability.

## Suggested implementation order

1. Fix build configuration isolation and header dependency tracking together (F02, F06).
2. Fix shared job state (F01).
3. Fix dependency closure and test selection together (F03, F04).
4. Fix executable-relative discovery and explicit script working directories (F05).
5. Fix prefix-scoped package checks and the bzip2 test argument (F07, F08).
6. Correct the README debugging command (D01), run focused checks, and report any checks that could not be run.

P1 means a high-priority correctness problem. P2 means a normal-priority functional defect. Avoid unrelated refactoring or dependency/version updates while implementing these fixes.

## F01 — P1: Concurrent jobs can interfere with each other

Locations: `main.cpp`, `onInstall()` around line 938, `onBuildTests()` around line 1008, and `applyUiUpdate()` around lines 571–574.

### Cause and impact

`onInstall()` disables only `installBtn`; `onBuildTests()` disables only `buildTestBtn`. Both worker types send the same completion update, and `applyUiUpdate()` enables both buttons whenever any job completes. There is no shared busy guard in either handler.

Consequently an installation and a test can overlap. Once either completes, another installation can start even if the original installation is still running. Installers share source/build paths and perform unsynchronized read-modify-write updates to `res/installed.ini`; overlapping installations can collide, remove each other's files, or lose tracking entries. Both worker types also modify the process-wide PATH, and both write to the same output pane.

### Reproduction scenario

1. Start a long-running installation.
2. Switch to Test and start a short test.
3. Let the test finish while installation continues.
4. Observe that both action buttons become enabled, allowing a second installation.

### Implementation guidance

- Introduce one shared job-active state managed on the UI thread.
- Guard both handlers against starting a job while another is active; disabled buttons alone are insufficient protection.
- Disable both action buttons before starting either worker.
- Restore both buttons and clear the state on normal completion, worker-reported failure, and thread-creation failure.
- Keep validation/no-selection early returns from leaving the UI busy. Take care with the point at which state is acquired.
- Preserve responsive UI operation and queued output. A single-job policy is sufficient; a job scheduler is unnecessary.

### Acceptance criteria

- An active install prevents tests and further installs; an active test prevents installs and further tests.
- No completion can make actions available while a job is still active.
- Success, missing-shell/process failure, and thread-creation failure all restore usable controls exactly once.
- Output is not cleared by a rejected overlapping action.

## F02 — P1: Debug builds reuse Release objects

Locations: `Makefile`, `BUILD_DIR := build` around line 38, configuration flags around lines 22–30, and target/object rules around lines 72–106.

### Cause and impact

Debug and Release have distinct executable names but share every object and `libui.a`. Make compares prerequisites and timestamps; changing `config` does not invalidate existing objects. Relinking Release objects with `-g -DDEBUG` cannot add compilation-time debug information or enable `#ifdef DEBUG` code. The reverse configuration transition can also reuse Debug objects.

Observed evidence: the review's `make -n config=Debug` emitted only a link command against the existing shared artifacts.

### Implementation guidance

- Put all intermediate objects, the static archive, dependency files, and resources in configuration-specific directories, such as `build/Release/` and `build/Debug/`.
- Preserve root output names `w64devkit-tools.exe` and `w64devkit-tools-debug.exe`.
- Update every dependent path and directory-creation rule consistently. Preserve parallel builds.
- Keep `make clean` aligned with the resulting directory layout.
- Do not rely on users remembering to clean between configurations.

### Acceptance criteria

- Building Release then Debug without cleaning compiles separate Debug objects with `-g -DDEBUG`.
- Building Debug then Release uses Release objects and release flags.
- Both executables can coexist and be rebuilt independently.
- A repeated unchanged build of either configuration performs no unnecessary work.
- `make -j4` and `make -j4 config=Debug` succeed on Windows with the available toolchain.

## F03 — P2: Test-tab selection omits transitive library dependencies

Locations: `main.cpp`, `onSelectAllTests()` around lines 363–379 and `testModelSetCellValue()` around lines 475–499. Compare `selectDeps()` around line 331.

### Cause and impact

The test selection handlers set flags for directly named libraries, but do not call `selectDeps()`. Selecting the HarfBuzz test therefore selects `harfbuzz` without selecting its dependency `freetype` and FreeType's dependencies `zlib` and `bz2`. Installing the selected libraries into a clean prefix can fail.

### Implementation guidance

- Apply recursive dependency selection to every library selected through either test-selection path.
- Reuse or consolidate the existing dependency-selection helper instead of maintaining another traversal.
- Ensure dependencies are resolved even if a direct library was already selected through a different path.
- Notify the library table for changed rows.
- Preserve the existing distinction between selecting tests and actually installing libraries; selecting a test must not launch installation.
- Traversal must terminate on cycles and avoid duplicate work.

### Acceptance criteria

- From an empty selection, selecting the HarfBuzz test selects `harfbuzz`, `freetype`, `zlib`, and `bz2`.
- Test-tab Select All produces the full dependency closure of all test dependencies.
- Repeated selections remain stable and do not recurse indefinitely.
- No installation is started merely by selecting tests.

## F04 — P2: Manually unchecking a dependency produces an invalid install job

Locations: `main.cpp`, `libModelSetCellValue()` around lines 421–434 and install job construction in `onInstall()` around lines 896–920.

### Cause and impact

Checking a library auto-selects dependencies, but unchecking a dependency is permitted without changing its dependents. The install handler only sorts currently selected entries by precomputed level. It does not recompute or validate their dependency closure. Sorting an incomplete selection cannot ensure dependencies are installed.

### Reproduction scenario

Select `harfbuzz`, manually uncheck `freetype`, then install into a prefix where FreeType is absent. The job omits a required dependency.

### Implementation guidance

- Resolve dependency closure when constructing the install job, using selected libraries as roots.
- Deduplicate entries and order dependencies before dependents.
- Apply installed-library skipping after dependency resolution, preserving Force Update semantics.
- Choose a clear UI behavior if omitted dependencies are automatically added; keep displayed selection/output consistent with the actual job.
- Detect an unknown dependency or cycle in a requested closure and report an actionable error instead of starting a knowingly invalid order. Existing startup warnings can remain.
- Do not conflate a library's metadata display name with its filename stem; current dependency matching uses `Library::name`.

### Acceptance criteria

- Unchecking a required dependency cannot silently produce an incomplete job.
- Every required dependency is either included before its dependent or legitimately skipped as installed for that prefix.
- Each library runs at most once per job.
- Force Update includes already tracked required dependencies.
- Missing dependencies and cycles produce a clear failure without starting a partial invalid job.

## F05 — P2: Discovery and execution rely on the launch directory and path substrings

Locations: `main.cpp`, `initLibs()` around line 184, `initTests()` around line 286, and `runScriptStreamed()` around lines 675–697.

### Cause and impact

Discovery searches relative `scripts/install_*.sh` and `tests/test_*.sh` paths and reads metadata relative to the process working directory. Absolute installer paths are constructed only after discovery, so they do not fix launching from another directory.

Execution chooses the child working directory by testing whether the entire script path contains `test`. For an installer under `C:/testing/w64devkit-tools/`, this selects `tests` rather than `scripts`. All child working directories are also relative to the parent working directory.

### Implementation guidance

- Resolve the executable's directory once and use it for script/test enumeration and metadata reads.
- Store absolute script paths for both installers and tests.
- Pass an explicit absolute working directory to `runScriptStreamed()`, or derive it from the script's parent directory. Do not infer job type from substrings.
- Preserve test scripts' access to their adjacent C/C++ sources and installers' expected extraction/build location.
- Handle spaces in paths and use consistent encoding when passing paths to Windows APIs. Avoid mixing ANSI-derived path bytes with UTF-8 conversion without a defined conversion.
- Give a useful error if required directories are absent rather than silently presenting unexplained empty tables.

### Acceptance criteria

- Launch from the project directory and from an unrelated working directory; both discover the same libraries and tests.
- Run one installer and one test from each launch location.
- A project directory whose name contains `test` does not redirect installers into the test directory.
- Paths with spaces work and tests can locate their source files.

## F06 — P2: Header edits do not invalidate object files

Locations: `Makefile`, `main.o` and libui object pattern rules around lines 93–106. Resource prerequisites are around lines 111–114.

### Cause and impact

Compilation rules list only their source files. Included headers such as `libui-ng/ui.h` and backend headers are absent from the dependency graph. Editing a header can leave stale objects, potentially mixing incompatible declarations and implementations.

### Implementation guidance

- Generate per-object compiler dependency files using `-MMD -MP` for both C and C++ compilation.
- Include the resulting `.d` files with optional inclusion so a clean checkout builds successfully.
- Keep dependency files inside the configuration-specific directories introduced for F02.
- Review resource inputs separately: compiler-generated C/C++ dependency files do not cover the resource compiler. In particular, add the icon referenced by `resources.rc` to the resource target's prerequisites.

### Acceptance criteria

- After an initial build, updating the timestamp of `ui.h` schedules recompilation of the application and affected libui sources.
- Updating a backend-only header rebuilds the affected backend objects.
- Changing the icon schedules resource recompilation and relinking.
- Missing `.d` files do not fail a clean build; unchanged incremental builds remain no-ops.
- Verify both configurations without permanently modifying header or icon contents.

## F07 — P2: The shared skip check can accept a package from another prefix

Location: `scripts/common.sh`, `skip_if_installed()` around line 14. Also inspect child environment setup in `installThread()` and `buildTestThread()`.

### Cause and impact

The skip helper treats either `pkg-config --exists <name>` or the prefix-local marker file as sufficient evidence of installation. Package lookup uses inherited/default search paths, without verifying that the package belongs to `INSTALL_PREFIX`. If another prefix provides a matching `.pc` file, the installer can exit successfully even though the requested prefix lacks the library. The GUI then records it as installed for the requested prefix.

The worker prepends `<prefix>/bin` to PATH, but that does not guarantee prefix-local pkg-config resolution when inherited `PKG_CONFIG_PATH` or related configuration points elsewhere.

### Implementation guidance

- Make skip decisions use evidence belonging to the requested prefix.
- Either restrict pkg-config lookup for the check to appropriate prefix-local locations, or verify resolved package ownership before accepting the result. A prefix-local marker can also provide the required evidence where appropriate.
- Consider `lib/pkgconfig`, `share/pkgconfig`, and any other directories actually produced by supported installers. Do not hardcode one directory without checking coverage.
- Account for both additive `PKG_CONFIG_PATH` and default search paths controlled by `PKG_CONFIG_LIBDIR`; setting only an additive path may leave foreign packages visible.
- Preserve Force Update bypass, existing helper arguments, and shared-preamble usage.
- Keep any environment scoping deliberate so installation checks, dependency discovery, and tests do not silently disagree about the selected prefix.
- Do not automatically delete or rewrite existing `installed.ini` entries as part of this fix. Existing stale records are a separate state-reconciliation concern.

### Acceptance criteria

- Create isolated prefixes A and B, with a matching `.pc` file only in A, and expose A through inherited pkg-config configuration. Checking B must not report that its package is installed.
- A valid package/marker in B still skips when Force Update is false.
- Force Update true bypasses the skip even when B has a matching package or marker.
- Exercise the helper safely in a subprocess because it calls `exit 0`; do not run download/build commands just to validate the skip decision.

## F08 — P2: The bzip2 test ignores the prefix argument

Location: `tests/test_bz2.sh`, line 7. Compare prefix parsing in `tests/test_curl.sh` and `tests/test_go.sh`.

### Cause and impact

The GUI passes the selected prefix as the test script's first positional argument. `test_bz2.sh` instead reads only `${INSTALL_PREFIX:-C:/w64devkit}`. The GUI does not export `INSTALL_PREFIX`, so a test selected for a custom prefix uses the default prefix's include and library paths. It may fail or validate the wrong installation.

### Implementation guidance

- Read the positional prefix argument, following the existing convention in the curl/Go tests, for example `PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"`.
- Preserve quoting for paths containing spaces.
- If the broader implementation instead standardizes exporting the selected prefix, explicitly verify consistency across all tests and preserve standalone positional-argument use.

### Acceptance criteria

- With `INSTALL_PREFIX` unset, passing a custom `$1` yields compiler `-I` and `-L` options for that prefix.
- Omitting both sources preserves the default `C:/w64devkit`.
- Environment override precedence remains consistent with the other test scripts.
- Verify argument forwarding with a stub compiler if a full bzip2 installation is unavailable; report that limitation.

## D01 — Documentation: Debugger example selects the Release executable

Location: `README.md`, line 21.

After showing `make -j4 config=Debug`, the README runs `gdb -x gdb_watch.cmd w64devkit-tools.exe`. The Makefile's Debug target is `w64devkit-tools-debug.exe`.

Change the example to:

```sh
make -j4 config=Debug
gdb -x gdb_watch.cmd w64devkit-tools-debug.exe
```

Acceptance: the documented debugger command names the executable actually produced by the preceding build command.

## Completion checklist for the implementing agent

- Address every finding or explicitly document why it remains unresolved.
- Keep fixes focused and preserve unrelated working-tree changes.
- Run meaningful focused verification for job exclusion, dependency closure/order, configuration switching, header rebuilds, launch directories, and prefix selection. Use isolated fixtures or stubs where practical to avoid downloads and real-prefix modifications.
- Run the Windows Release and Debug builds when toolchain access permits. Syntax checks alone do not replace those builds.
- Re-run shell syntax checks for changed scripts and metadata validation if script headers change.
- Review the final diff for accidental artifact churn. Do not delete tracked build artifacts merely because they are generated.
- In the implementation summary, distinguish checks actually run from expected behavior and list any remaining risks or blocked checks. Do not claim that library installs or GUI scenarios passed unless they were exercised.

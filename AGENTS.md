# w64devkit-tools

Windows-only native GUI (libui-ng) app for managing C/C++ library installs into w64devkit prefixes.

## Build

```sh
make -j4                          # release (stripped, static, -mwindows)
make -j4 config=Debug             # debug (-g, -DDEBUG)
make clean                        # rm -rf build/
```

Requires MinGW-w64 (w64devkit). **Cannot build on Linux/macOS** — bundled libui-ng only has a `windows/` backend.

## Architecture

- **Single source file:** `main.cpp` (~810 lines) — the entire app.
- **25 install scripts:** `scripts/install_*.sh` — each must have these headers:
  `#deps:`, `#desc:`, `#version:`, `#name:`. Use `#deps: none` if none.
  All scripts source `scripts/common.sh` for shared argument parsing and the
  `skip_if_installed()` helper — never duplicate that boilerplate.
- **Shared preamble:** `scripts/common.sh` — provides `INSTALL_PREFIX`, `FORCE_UPDATE`,
  and `skip_if_installed(pkgconfig_name, lib_path, display_name)`.
- **Default prefix** (hardcoded): `C:/x86devkit`.
- **Installed tracking:** `res/installed.ini` (gitignored). Format: `C:/path=lib1 lib2 ...`

## Quirks

- No tests, lint, typecheck, CI/CD, or package manager.
- Fully statically linked (`-static -static-libgcc -static-libstdc++`).
- Build artifacts (`build/`) are checked into git.
- Output pane trims at ~25K chars to 20K + `"\n--- trimmed ---\n"`.
- `Force Update` checkbox skips "already installed" check.
- Dep names in `#deps:` headers are validated against known libraries at startup; unknown deps print a warning to stderr.
- Each install script sources `scripts/common.sh` which reads `$1` (prefix) and `$2` (force update flag).

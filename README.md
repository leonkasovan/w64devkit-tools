# w64devkit-tools

A native Windows GUI application (libui-ng) for managing and installing libraries into a [w64devkit](https://github.com/skeeto/w64devkit) environment.

## Features

- Browse 20+ libraries (zlib, SDL2, curl, freetype, opus, etc.)
- Automatic dependency resolution and topological install order
- Installs to a user-specified prefix (default: `C:/w64devkit`)
- Tracks installed libraries per prefix in `res/installed.ini`
- Streaming output display during script execution

## Building

Requires [w64devkit](https://github.com/skeeto/w64devkit) (MinGW-w64 + make).

```sh
make -j4                        # Release build (stripped)

make -j4 config=Debug           # Debug build (-g, -DDEBUG, no strip)
gdb -x gdb_watch.cmd w64devkit-tools.exe
```

This compiles the libui-ng bundled library and links the executable.

## Usage

```sh
./w64devkit-tools.exe
```

1. Select the libraries to install via the checkboxes
2. Optionally change the install prefix
3. Click **Install Selected**
4. Output appears in real-time as each install script runs

### Adding a new library

Create `scripts/install_<name>.sh` with these metadata headers:

```sh
#!/bin/bash
#deps: <dependency names, space or comma separated>
#desc: Short description
#version: x.y.z
#name: Display Name
```

The script receives one argument: the install prefix. Exit 0 on success.

## Project structure

```
├── main.cpp           — GUI application
├── Makefile           — Build system
├── libui-ng/          — Bundled libui-ng source
├── scripts/           — Per-library install shell scripts
├── res/               — Resources (icon, manifest, rc, installed.ini)
```

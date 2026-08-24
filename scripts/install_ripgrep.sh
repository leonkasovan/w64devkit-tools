#!/bin/bash
set -e
#deps: none
#desc: Fast recursive grep (rg.exe, pre-built binary)
#version: 15.2.0
#name: ripgrep

source "$(dirname "$0")/common.sh"
skip_if_installed "ripgrep" "$INSTALL_PREFIX/bin/rg.exe" "ripgrep"

# Detect architecture from the compiler target
case "$(gcc -dumpmachine)" in
    x86_64*) ARCH=x86_64-pc-windows-gnu ;;
    i686*)   ARCH=i686-pc-windows-msvc ;;
    *)       echo "error: unsupported architecture"; exit 1 ;;
esac

RG_VER="15.2.0"
ZIP="ripgrep-${RG_VER}-${ARCH}.zip"
wget "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/${ZIP}" -O "$ZIP"
# sanity check: should be a zip archive (starts with PK header)
if [ "$(od -An -N2 -tx1 "$ZIP" | tr -d ' \n')" != "504b" ]; then
    echo "error: $ZIP is not a zip archive (download failed?)"
    exit 1
fi
unzip -qo "$ZIP"
mkdir -p "$INSTALL_PREFIX/bin"
cp -f "ripgrep-${RG_VER}-${ARCH}/rg.exe" "$INSTALL_PREFIX/bin/rg.exe"
rm -f "$ZIP"
rm -rf "ripgrep-${RG_VER}-${ARCH}"
echo "Test: \"$INSTALL_PREFIX\"/bin/rg.exe --version"

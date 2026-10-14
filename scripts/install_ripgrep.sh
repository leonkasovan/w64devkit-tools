#!/bin/bash
set -e
#deps: none
#desc: Fast recursive grep (ripgrep.exe)
#version: 15.2.0
#name: rg

source "$(dirname "$0")/common.sh"
skip_if_installed "rg" "$INSTALL_PREFIX/bin/rg.exe" "rg"

wget https://github.com/BurntSushi/ripgrep/releases/download/15.2.0/ripgrep-15.2.0-x86_64-pc-windows-gnu.zip -O ripgrep-15.2.0.zip
unzip -o ripgrep-15.2.0.zip || true
mkdir -p "$INSTALL_PREFIX/bin"
cp -f ripgrep-15.2.0-x86_64-pc-windows-gnu/rg.exe "$INSTALL_PREFIX/bin/"
rm -r ripgrep-15.2.0-x86_64-pc-windows-gnu ripgrep-15.2.0.zip
echo "Test: \"$INSTALL_PREFIX\"/bin/rg.exe --version"

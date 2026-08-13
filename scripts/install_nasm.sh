#!/bin/bash
set -e
#deps: none
#desc: Netwide Assembler (nasm.exe)
#version: 3.02
#name: nasm

source "$(dirname "$0")/common.sh"
skip_if_installed "nasm" "$INSTALL_PREFIX/bin/nasm.exe" "nasm"

wget https://www.nasm.us/pub/nasm/releasebuilds/3.02/nasm-3.02.tar.gz -O nasm-3.02.tar.gz
# sanity check: nasm.us can return an HTML error page instead of the file
if [ "$(od -An -N2 -tx1 nasm-3.02.tar.gz | tr -d ' \n')" != "1f8b" ]; then
    echo "error: nasm-3.02.tar.gz is not a gzip archive (download failed?)"
    exit 1
fi
tar -xf nasm-3.02.tar.gz
(
  cd nasm-3.02
  # The app runs scripts with w64devkit's busybox ash, which parses PATH as
  # colon-separated while the app passes a Windows (semicolon) PATH. Point
  # configure at the tools explicitly and skip host-type autodetection.
  ./configure --prefix="$INSTALL_PREFIX" --build=x86_64-w64-mingw32 \
      CC="$INSTALL_PREFIX/bin/gcc" \
      AR="$INSTALL_PREFIX/bin/ar" \
      RANLIB="$INSTALL_PREFIX/bin/ranlib" \
      STRIP="$INSTALL_PREFIX/bin/strip"
  make -j"$(nproc)"
  make install
)
rm -r nasm-3.02 nasm-3.02.tar.gz
echo "Test: \"$INSTALL_PREFIX\"/bin/nasm.exe -v"

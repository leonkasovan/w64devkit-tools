#!/bin/bash
set -e
#deps: opus
#desc: Opus audio file library
#version: 0.12
#name: opusfile

INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists opusfile 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libopusfile.a" ]; then
    echo "[SKIPPED] opusfile already installed"; exit 0
fi

wget https://github.com/xiph/opusfile/releases/download/v0.12/opusfile-0.12.zip
unzip -o opusfile-0.12.zip
(
  cd opusfile-0.12
  export PATH="$INSTALL_PREFIX/bin:$PATH"
  ./configure --disable-http --disable-examples --disable-doc --disable-shared --prefix="$INSTALL_PREFIX"
  make -j8
  make install
)
rm -r opusfile-0.12 opusfile-0.12.zip
echo "Test: ls $INSTALL_PREFIX/lib/libopusfile.a $INSTALL_PREFIX/include/opus/opusfile.h"

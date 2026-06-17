#!/bin/bash
set -e
#deps: none
#desc: Modern C++ formatting library
#version: 11.1.4
#name: fmt

INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists fmt 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libfmt.a" ] ); then
    echo "[SKIPPED] fmt already installed"; exit 0
fi

wget https://github.com/fmtlib/fmt/archive/refs/tags/11.1.4.tar.gz -O fmt-11.1.4.tar.gz
tar -xf fmt-11.1.4.tar.gz
cmake -S fmt-11.1.4 -B build-fmt -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DFMT_TEST=OFF -DFMT_DOC=OFF
cmake --build build-fmt --parallel
cmake --install build-fmt
rm -r build-fmt fmt-11.1.4 fmt-11.1.4.tar.gz
echo "Test: pkg-config --cflags --libs fmt"

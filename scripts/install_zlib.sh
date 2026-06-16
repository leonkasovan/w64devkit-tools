#!/bin/bash
#deps: none
#desc: Compression library
#version: 1.3.2
#name: zlib

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists zlib 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libz.a" ]; then
    echo "[SKIPPED] zlib already installed"; exit 0
fi

wget https://github.com/madler/zlib/archive/refs/tags/v1.3.2.zip -O zlib-v1.3.2.zip
unzip zlib-v1.3.2.zip
cmake -S zlib-1.3.2 -B build-zlib -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DZLIB_BUILD_SHARED=OFF -DZLIB_BUILD_TESTING=OFF -DZLIB_BUILD_TESTZLIB=OFF
cmake --build build-zlib --parallel
cmake --install build-zlib
rm -r build-zlib zlib-1.3.2 zlib-v1.3.2.zip
echo "Test: pkg-config --libs zlib"
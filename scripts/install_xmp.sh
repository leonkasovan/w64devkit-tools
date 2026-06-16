#!/bin/bash
set -e
#deps: none
#desc: Extended Module Player (music)
#version: 4.7.0
#name: xmp

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists libxmp 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libxmp.a" ]; then
    echo "[SKIPPED] xmp already installed"; exit 0
fi

wget https://github.com/libxmp/libxmp/releases/download/libxmp-4.7.0/libxmp-4.7.0.tar.gz
tar -xf libxmp-4.7.0.tar.gz
cmake -S libxmp-4.7.0 -B build_xmp -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED=OFF -DWITH_UNIT_TESTS=OFF
cmake --build build_xmp --parallel
cmake --install build_xmp
rm -r build_xmp libxmp-4.7.0 libxmp-4.7.0.tar.gz
echo "Test: pkg-config --cflags --libs libxmp"

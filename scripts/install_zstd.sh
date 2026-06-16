#!/bin/bash
set -e
#deps: none
#desc: Zstandard compression
#version: 1.5.7
#name: zstd

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists libzstd 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libzstd.a" ]; then
    echo "[SKIPPED] zstd already installed"; exit 0
fi

wget https://github.com/facebook/zstd/archive/refs/tags/v1.5.7.zip -O zstd-v1.5.7.zip
unzip -o zstd-v1.5.7.zip
cmake -S zstd-1.5.7/build/cmake -B build-zstd -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_SHARED=OFF -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_TESTS=OFF -DBUILD_TESTING=OFF
cmake --build build-zstd --parallel
cmake --install build-zstd
rm -r build-zstd zstd-1.5.7 zstd-v1.5.7.zip
echo "Test: pkg-config --libs libzstd"

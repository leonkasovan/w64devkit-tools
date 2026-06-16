#!/bin/bash
set -e
#deps: none
#desc: Brotli compression
#version: 1.2.0
#name: brotli

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists libbrotlidec 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libbrotlicommon.a" ]; then
    echo "[SKIPPED] brotli already installed"; exit 0
fi

wget https://github.com/google/brotli/archive/refs/tags/v1.2.0.zip -O brotli-1.2.0.zip
unzip -o brotli-1.2.0.zip
cmake -S brotli-1.2.0 -B build-brotli -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DBROTLI_BUILD_TOOLS=OFF -DBROTLI_DISABLE_TESTS=OFF -DENABLE_COVERAGE=OFF
cmake --build build-brotli --parallel
cmake --install build-brotli
rm -r build-brotli brotli-1.2.0 brotli-1.2.0.zip
echo "Test: pkg-config --libs --cflags libbrotlienc libbrotlidec libbrotlicommon"

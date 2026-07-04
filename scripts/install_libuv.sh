#!/bin/bash
set -e
#deps: none
#desc: Cross-platform asynchronous I/O library
#version: 1.50.0
#name: libuv

INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists libuv 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libuv.a" ] ); then
    echo "[SKIPPED] libuv already installed"; exit 0
fi

wget https://github.com/libuv/libuv/archive/refs/tags/v1.50.0.tar.gz -O libuv-1.50.0.tar.gz
tar -xf libuv-1.50.0.tar.gz
cmake -S libuv-1.50.0 -B build-libuv -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DLIBUV_BUILD_TESTS=OFF
cmake --build build-libuv --parallel
cmake --install build-libuv
rm -r build-libuv libuv-1.50.0 libuv-1.50.0.tar.gz
echo "Test: pkg-config --cflags --libs libuv"

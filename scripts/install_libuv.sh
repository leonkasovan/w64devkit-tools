#!/bin/bash
set -e
#deps: none
#desc: Cross-platform asynchronous I/O library
#version: 1.50.0
#name: libuv

source "$(dirname "$0")/common.sh"
skip_if_installed "libuv" "$INSTALL_PREFIX/lib/libuv.a" "libuv"

wget https://github.com/libuv/libuv/archive/refs/tags/v1.50.0.tar.gz -O libuv-1.50.0.tar.gz
tar -xf libuv-1.50.0.tar.gz
cmake -S libuv-1.50.0 -B build-libuv -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DLIBUV_BUILD_TESTS=OFF
cmake --build build-libuv --parallel
cmake --install build-libuv
rm -r build-libuv libuv-1.50.0 libuv-1.50.0.tar.gz
echo "Test: pkg-config --cflags --libs libuv"

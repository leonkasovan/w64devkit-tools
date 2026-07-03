#!/bin/bash
set -e
#deps: none
#desc: Compression library
#version: 1.3.2
#name: zlib

source "$(dirname "$0")/common.sh"
skip_if_installed "zlib" "$INSTALL_PREFIX/lib/libz.a" "zlib"

wget https://github.com/madler/zlib/archive/refs/tags/v1.3.2.zip -O zlib-v1.3.2.zip
unzip -o zlib-v1.3.2.zip
cmake -S zlib-1.3.2 -B build-zlib -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DZLIB_BUILD_SHARED=OFF -DZLIB_BUILD_TESTING=OFF -DZLIB_BUILD_TESTZLIB=OFF
cmake --build build-zlib --parallel
cmake --install build-zlib
rm -r build-zlib zlib-1.3.2 zlib-v1.3.2.zip
echo "Test: pkg-config --libs zlib"

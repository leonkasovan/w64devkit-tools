#!/bin/bash
set -e
#deps: zlib, zstd, bz2, lzma
#desc: Minizip compression library
#version: 4.2.2
#name: minizip

source "$(dirname "$0")/common.sh"
skip_if_installed "minizip" "$INSTALL_PREFIX/lib/libminizip.a" "minizip"

wget https://github.com/zlib-ng/minizip-ng/archive/refs/tags/4.2.2.zip -O minizip-4.2.2.zip
unzip -o minizip-4.2.2.zip
cmake -S minizip-ng-4.2.2 -B build-minizip -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DZLIB_LIBRARY="$INSTALL_PREFIX"/lib/libzs.a -DBUILD_SHARED_LIBS=OFF -DMZ_FETCH_LIBS=OFF -DMZ_PPMD=OFF -DMZ_BUILD_TESTS=OFF
cmake --build build-minizip --parallel
cmake --install build-minizip
rm -r build-minizip minizip-ng-4.2.2 minizip-4.2.2.zip
echo "Test: pkg-config --cflags --libs minizip"

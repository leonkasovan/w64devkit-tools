#!/bin/bash
set -e
#deps: none
#desc: XZ/LZMA compression library
#version: 5.8.3
#name: lzma

source "$(dirname "$0")/common.sh"
skip_if_installed "liblzma" "$INSTALL_PREFIX/lib/liblzma.a" "lzma"

wget https://github.com/tukaani-project/xz/releases/download/v5.8.3/xz-5.8.3.tar.gz -O xz-5.8.3.tar.gz
tar -xf xz-5.8.3.tar.gz
cmake -S xz-5.8.3 -B build-lzma -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF
cmake --build build-lzma --parallel
cmake --install build-lzma
rm -r build-lzma xz-5.8.3 xz-5.8.3.tar.gz
echo "Test: pkg-config --cflags --libs liblzma"

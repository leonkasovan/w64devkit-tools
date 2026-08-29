#!/bin/bash
set -e
#deps: none
#desc: Zstandard compression
#version: 1.5.7
#name: zstd

source "$(dirname "$0")/common.sh"
skip_if_installed "libzstd" "$INSTALL_PREFIX/lib/libzstd.a" "zstd"

wget https://github.com/facebook/zstd/archive/refs/tags/v1.5.7.zip -O zstd-v1.5.7.zip
unzip -o zstd-v1.5.7.zip || true
cmake -S zstd-1.5.7/build/cmake -B build-zstd -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_SHARED=OFF -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_TESTS=OFF -DBUILD_TESTING=OFF
cmake --build build-zstd --parallel
cmake --install build-zstd
rm -r build-zstd zstd-1.5.7 zstd-v1.5.7.zip
echo "Test: pkg-config --libs libzstd"

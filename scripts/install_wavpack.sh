#!/bin/bash
set -e
#deps: none
#desc: WavPack audio compression
#version: 5.9.0
#name: wavpack

source "$(dirname "$0")/common.sh"
skip_if_installed "wavpack" "$INSTALL_PREFIX/lib/libwavpack.a" "wavpack"

wget https://github.com/dbry/WavPack/archive/refs/tags/5.9.0.zip -O wavpack-5.9.0.zip
unzip -o wavpack-5.9.0.zip
cmake -S WavPack-5.9.0 -B build_wavpack -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DWAVPACK_BUILD_PROGRAMS=OFF -DBUILD_TESTING=OFF -DWAVPACK_INSTALL_DOCS=OFF
cmake --build build_wavpack --parallel
cmake --install build_wavpack
rm -r WavPack-5.9.0 build_wavpack wavpack-5.9.0.zip
echo "Test: pkg-config --cflags --libs wavpack"

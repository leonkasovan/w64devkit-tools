#!/bin/bash
#deps: none
#desc: WavPack audio compression
#version: 5.9.0
#name: wavpack

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

wget https://github.com/dbry/WavPack/archive/refs/tags/5.9.0.zip -O wavpack-5.9.0.zip
unzip wavpack-5.9.0.zip
cmake -S WavPack-5.9.0 -B build_wavpack -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DWAVPACK_BUILD_PROGRAMS=OFF -DBUILD_TESTING=OFF -DWAVPACK_INSTALL_DOCS=OFF
cmake --build build_wavpack --parallel
cmake --install build_wavpack
rm -r WavPack-5.9.0 build_wavpack wavpack-5.9.0.zip
echo "Test: pkg-config --cflags --libs wavpack"
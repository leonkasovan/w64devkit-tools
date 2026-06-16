#!/bin/bash
#deps: none
#desc: Simple game/graphics library
#version: 6.0
#name: raylib6

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

wget https://github.com/raysan5/raylib/archive/refs/tags/6.0.zip -O raylib-6.0.zip
unzip raylib-6.0.zip
cmake -S raylib-6.0 -B build-raylib6 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
cmake --build build-raylib6 --parallel
cmake --install build-raylib6
rm -r build-raylib6 raylib-6.0 raylib-6.0.zip
echo "Test: pkg-config --cflags --libs raylib"
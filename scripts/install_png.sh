#!/bin/bash
#deps: zlib
#desc: PNG image library
#version: 1.6.58
#name: png

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

wget https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.58.zip -O png-1.6.58.zip
unzip png-1.6.58.zip
cmake -S libpng-1.6.58 -B build_png -DPNG_SHARED=OFF -DPNG_TOOLS=OFF -DPNG_TESTS=OFF -DPNG_STATIC=ON -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DZLIB_LIBRARY="$INSTALL_PREFIX"/lib/libzs.a
cmake --build build_png --parallel
cmake --install build_png
rm -r build_png libpng-1.6.58 png-1.6.58.zip
echo "Test: pkg-config --cflags --libs libpng"
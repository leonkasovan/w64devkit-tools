#!/bin/bash
set -e
#deps: none
#desc: Simple DirectMedia Layer 3
#version: 3.2.8
#name: sdl3

source "$(dirname "$0")/common.sh"
skip_if_installed "sdl3" "$INSTALL_PREFIX/lib/libSDL3.a" "sdl3"

wget https://github.com/libsdl-org/SDL/archive/refs/tags/release-3.2.8.zip -O sdl3-3.2.8.zip
unzip -o sdl3-3.2.8.zip
cmake -S SDL-release-3.2.8 -B build-sdl3 -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_TEST=OFF -DSDL_TESTS=OFF
cmake --build build-sdl3 --parallel
cmake --install build-sdl3
rm -r build-sdl3 SDL-release-3.2.8 sdl3-3.2.8.zip
echo "Test: pkg-config --cflags --libs sdl3"

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
# Patch sdl3.pc to use the static library directly so consumers don't need
# the sed workaround to force -l:libSDL3.a.
sed -i 's/-lSDL3\b/-l:libSDL3.a/g' "$INSTALL_PREFIX/lib/pkgconfig/sdl3.pc"
# Remove any stray shared import lib so downstream consumers don't pull in
# SDL3.dll at runtime.
rm -f "$INSTALL_PREFIX/lib/libSDL3.dll.a"
rm -r build-sdl3 SDL-release-3.2.8 sdl3-3.2.8.zip
echo "Test: pkg-config --cflags --libs sdl3"

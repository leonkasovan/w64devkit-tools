#!/bin/bash
set -e
#deps: none
#desc: Simple DirectMedia Layer
#version: 2.32.10
#name: sdl2

source "$(dirname "$0")/common.sh"
skip_if_installed "sdl2" "$INSTALL_PREFIX/lib/libSDL2.a" "sdl2"

wget https://github.com/libsdl-org/SDL/archive/refs/tags/release-2.32.10.zip -O sdl2-2.32.10.zip
unzip -o sdl2-2.32.10.zip || true
cmake -S SDL-release-2.32.10 -B build-sdl2 -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_OPENGL=ON -DSDL_OPENGLES=OFF -DSDL_RENDER_D3D=OFF -DSDL_VULKAN=OFF -DSDL_DIRECTX=OFF -DSDL_OFFSCREEN=OFF -DSDL_DUMMYVIDEO=OFF -DSDL_WAYLAND=OFF -DSDL_X11=OFF -DSDL_COCOA=OFF -DSDL_TEST=OFF -DSDL_TESTS=OFF -DSDL_INSTALL_TESTS=OFF
cmake --build build-sdl2 --parallel
cmake --install build-sdl2
# Remove any stray shared import lib so downstream consumers (and pkg-config
# -lSDL2) link the static libSDL2.a instead of pulling in SDL2.dll at runtime.
rm -f "$INSTALL_PREFIX/lib/libSDL2.dll.a"
rm -r build-sdl2 SDL-release-2.32.10 sdl2-2.32.10.zip
echo "Test: pkg-config --libs --cflags sdl2"


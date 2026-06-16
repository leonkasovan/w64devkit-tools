#!/bin/bash
set -e
#deps: none
#desc: Simple DirectMedia Layer
#version: 2.32.10
#name: sdl2

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists sdl2 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libSDL2.a" ]; then
    echo "[SKIPPED] sdl2 already installed"; exit 0
fi

wget https://github.com/libsdl-org/SDL/archive/refs/tags/release-2.32.10.zip -O sdl2-2.32.10.zip
unzip -o sdl2-2.32.10.zip
cmake -S SDL-release-2.32.10 -B build-sdl2 -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_OPENGL=ON -DSDL_OPENGLES=OFF -DSDL_RENDER_D3D=OFF -DSDL_VULKAN=OFF -DSDL_DIRECTX=OFF -DSDL_OFFSCREEN=OFF -DSDL_DUMMYVIDEO=OFF -DSDL_WAYLAND=OFF -DSDL_X11=OFF -DSDL_COCOA=OFF -DSDL_TEST=OFF -DSDL_TESTS=OFF -DSDL_INSTALL_TESTS=OFF
cmake --build build-sdl2 --parallel
cmake --install build-sdl2
rm -r build-sdl2 SDL-release-2.32.10 sdl2-2.32.10.zip
echo "Test: pkg-config --libs --cflags sdl2"


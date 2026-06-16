#!/bin/bash
set -e
#deps: sdl2, freetype
#desc: SDL2 TrueType font rendering
#version: 2.24.0
#name: sdl2ttf

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists SDL2_ttf 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libSDL2_ttf.a" ]; then
    echo "[SKIPPED] sdl2ttf already installed"; exit 0
fi

wget https://github.com/libsdl-org/SDL_ttf/archive/refs/tags/release-2.24.0.zip -O sdl2_ttf-2.24.0.zip
unzip -o sdl2_ttf-2.24.0.zip
cmake -S SDL_ttf-release-2.24.0 -B build_sdl2ttf -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DSDL2TTF_SAMPLES=OFF -DBUILD_SHARED_LIBS=OFF
cmake --build build_sdl2ttf --parallel
cmake --install build_sdl2ttf
rm -r build_sdl2ttf SDL_ttf-release-2.24.0 sdl2_ttf-2.24.0.zip
echo "Test: pkg-config --cflags --libs SDL2_ttf"

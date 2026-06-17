#!/bin/bash
set -e
#deps: sdl2, png, libwebp, libjpeg
#desc: SDL2 image loading library
#version: 2.8.12
#name: sdl2image

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists SDL2_image 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libSDL2_image.a" ] ); then
    echo "[SKIPPED] sdl2image already installed"; exit 0
fi

wget https://github.com/libsdl-org/SDL_image/archive/refs/tags/release-2.8.12.zip -O sdl2image-2.8.12.zip
unzip -o sdl2image-2.8.12.zip
cmake -S SDL_image-release-2.8.12 -B build_sdl2image -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DSDL2IMAGE_SAMPLES=OFF -DSDL2IMAGE_TESTS=OFF
cmake --build build_sdl2image --parallel
cmake --install build_sdl2image
rm -r build_sdl2image SDL_image-release-2.8.12 sdl2image-2.8.12.zip
echo "Test: pkg-config --cflags --libs SDL2_image"

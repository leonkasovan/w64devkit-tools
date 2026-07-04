#!/bin/bash
set -e
#deps: sdl2, png, webp, jpeg
#desc: SDL2 image loading library
#version: 2.8.12
#name: sdl2image

source "$(dirname "$0")/common.sh"
skip_if_installed "SDL2_image" "$INSTALL_PREFIX/lib/libSDL2_image.a" "sdl2image"

wget https://github.com/libsdl-org/SDL_image/archive/refs/tags/release-2.8.12.zip -O sdl2image-2.8.12.zip
unzip -o sdl2image-2.8.12.zip || true
cmake -S SDL_image-release-2.8.12 -B build_sdl2image -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DSDL2IMAGE_SAMPLES=OFF -DSDL2IMAGE_TESTS=OFF
cmake --build build_sdl2image --parallel
cmake --install build_sdl2image
rm -r build_sdl2image SDL_image-release-2.8.12 sdl2image-2.8.12.zip
echo "Test: pkg-config --cflags --libs SDL2_image"

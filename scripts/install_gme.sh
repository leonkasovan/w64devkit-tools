#!/bin/bash
set -e
#deps: zlib
#desc: Game Music Emulator
#version: 0.6.5
#name: gme

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists libgme 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libgme.a" ] ); then
    echo "[SKIPPED] gme already installed"; exit 0
fi

wget https://github.com/libgme/game-music-emu/releases/download/0.6.5/libgme-0.6.5-src.zip
unzip -o libgme-0.6.5-src.zip
cmake -S libgme-0.6.5 -B build_gme -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DGME_BUILD_TESTING=OFF -DGME_BUILD_EXAMPLES=OFF -DZLIB_LIBRARY="$INSTALL_PREFIX"/lib/libzs.a
cmake --build build_gme --parallel
cmake --install build_gme
rm -r build_gme libgme-0.6.5 libgme-0.6.5-src.zip
echo "Test: pkg-config --cflags --libs libgme"

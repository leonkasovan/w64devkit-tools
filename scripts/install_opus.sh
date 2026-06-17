#!/bin/bash
set -e
#deps: ogg
#desc: Opus audio codec
#version: 1.6.1
#name: opus

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists opus 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libopus.a" ] ); then
    echo "[SKIPPED] opus already installed"; exit 0
fi

wget https://downloads.xiph.org/releases/opus/opus-1.6.1.tar.gz
tar -xf opus-1.6.1.tar.gz
cmake -S opus-1.6.1 -B build_opus -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF
cmake --build build_opus --parallel
cmake --install build_opus
rm -r opus-1.6.1 build_opus opus-1.6.1.tar.gz
echo "Test: pkg-config --cflags --libs opus"

#!/bin/bash
set -e
#deps: zlib, bz2
#desc: Font rendering library
#version: 2.14.3
#name: freetype

source "$(dirname "$0")/common.sh"
skip_if_installed "freetype2" "$INSTALL_PREFIX/lib/libfreetype.a" "freetype"

wget https://github.com/libsdl-org/freetype/archive/refs/tags/VER-2-14-3.zip -O freetype-2.14.3.zip
unzip -o freetype-2.14.3.zip
cmake -S freetype-VER-2-14-3 -B build_freetype -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_FRAMEWORK=OFF -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DZLIB_LIBRARY="$INSTALL_PREFIX"/lib/libzs.a
cmake --build build_freetype --parallel
cmake --install build_freetype
rm -r build_freetype freetype-VER-2-14-3 freetype-2.14.3.zip
echo "Test: pkg-config --cflags --libs freetype2"

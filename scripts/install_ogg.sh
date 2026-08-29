#!/bin/bash
set -e
#deps: none
#desc: Ogg audio container
#version: 1.3.6
#name: ogg

source "$(dirname "$0")/common.sh"
skip_if_installed "ogg" "$INSTALL_PREFIX/lib/libogg.a" "ogg"

wget https://downloads.xiph.org/releases/ogg/libogg-1.3.6.zip
unzip -o libogg-1.3.6.zip
cmake -S libogg-1.3.6 -B build_ogg -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DINSTALL_DOCS=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_FRAMEWORK=OFF -DBUILD_TESTING=OFF
cmake --build build_ogg --parallel
cmake --install build_ogg
rm -r libogg-1.3.6 build_ogg libogg-1.3.6.zip
echo "Test: pkg-config --cflags --libs ogg"

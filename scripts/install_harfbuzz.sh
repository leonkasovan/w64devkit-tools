#!/bin/bash
set -e
#deps: freetype
#desc: Text shaping library
#version: 10.4.0
#name: harfbuzz

source "$(dirname "$0")/common.sh"
skip_if_installed "harfbuzz" "$INSTALL_PREFIX/lib/libharfbuzz.a" "harfbuzz"

wget https://github.com/harfbuzz/harfbuzz/archive/refs/tags/10.4.0.tar.gz -O harfbuzz-10.4.0.tar.gz
tar -xf harfbuzz-10.4.0.tar.gz
cmake -S harfbuzz-10.4.0 -B build-harfbuzz -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DHB_HAVE_FREETYPE=ON -DHB_HAVE_GLIB=OFF -DHB_HAVE_CAIRO=OFF -DHB_BUILD_SUBSET=OFF -DHB_HAVE_ICU=OFF
cmake --build build-harfbuzz --parallel
cmake --install build-harfbuzz
rm -r build-harfbuzz harfbuzz-10.4.0 harfbuzz-10.4.0.tar.gz
echo "Test: pkg-config --cflags --libs harfbuzz"

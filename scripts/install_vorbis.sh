#!/bin/bash
set -e
#deps: ogg
#desc: Ogg Vorbis audio decoder
#version: 1.3.7
#name: vorbis

source "$(dirname "$0")/common.sh"
skip_if_installed "vorbis" "$INSTALL_PREFIX/lib/libvorbis.a" "vorbis"

wget https://github.com/xiph/vorbis/archive/refs/tags/v1.3.7.tar.gz -O vorbis-1.3.7.tar.gz
tar -xf vorbis-1.3.7.tar.gz
cmake -S vorbis-1.3.7 -B build-vorbis -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF
cmake --build build-vorbis --parallel
cmake --install build-vorbis
rm -r build-vorbis vorbis-1.3.7 vorbis-1.3.7.tar.gz
echo "Test: pkg-config --cflags --libs vorbis"

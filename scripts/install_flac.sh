#!/bin/bash
set -e
#deps: ogg
#desc: FLAC audio codec
#version: 1.5.0
#name: flac

source "$(dirname "$0")/common.sh"
skip_if_installed "flac" "$INSTALL_PREFIX/lib/libFLAC.a" "flac"

wget https://ftp.osuosl.org/pub/xiph/releases/flac/flac-1.5.0.tar.xz
tar -xJf flac-1.5.0.tar.xz
cmake -S flac-1.5.0 -B build_flac -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DBUILD_CXXLIBS=OFF -DBUILD_PROGRAMS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DBUILD_DOCS=OFF -DINSTALL_MANPAGES=OFF -DWITH_OGG=ON -DENABLE_MULTITHREADING=OFF
cmake --build build_flac --parallel
cmake --install build_flac
rm -r build_flac flac-1.5.0 flac-1.5.0.tar.xz
echo "Test: pkg-config --cflags --libs flac"

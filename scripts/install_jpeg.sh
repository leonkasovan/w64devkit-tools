#!/bin/bash
set -e
#deps: none
#desc: JPEG image library (libjpeg-turbo)
#version: 3.1.0
#name: jpeg

source "$(dirname "$0")/common.sh"
skip_if_installed "libjpeg" "$INSTALL_PREFIX/lib/libjpeg.a" "jpeg"

wget https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.1.0/libjpeg-turbo-3.1.0.tar.gz -O libjpeg-turbo-3.1.0.tar.gz
tar -xf libjpeg-turbo-3.1.0.tar.gz
cmake -S libjpeg-turbo-3.1.0 -B build-libjpeg -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DENABLE_SHARED=OFF -DENABLE_STATIC=ON -DWITH_JPEG8=ON -DWITH_SIMD=OFF -DWITH_TURBOJPEG=OFF -DWITH_JAVA=OFF
cmake --build build-libjpeg --parallel
cmake --install build-libjpeg
rm -r build-libjpeg libjpeg-turbo-3.1.0 libjpeg-turbo-3.1.0.tar.gz
echo "Test: pkg-config --cflags --libs libjpeg"

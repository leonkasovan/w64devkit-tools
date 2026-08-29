#!/bin/bash
set -e
#deps: none
#desc: Ultralightweight JSON parser in ANSI C
#version: 1.7.19
#name: cjson

source "$(dirname "$0")/common.sh"
skip_if_installed "libcjson" "$INSTALL_PREFIX/lib/libcjson.a" "cjson"

wget https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.19.zip -O cjson-1.7.19.zip
unzip -o cjson-1.7.19.zip
cmake -S cJSON-1.7.19 -B build-cjson -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DENABLE_CJSON_TEST=OFF -DENABLE_CJSON_UTILS=ON
cmake --build build-cjson --parallel
cmake --install build-cjson
rm -r build-cjson cJSON-1.7.19 cjson-1.7.19.zip
echo "Test: pkg-config --cflags --libs libcjson"

#!/bin/bash
set -e
#deps: none
#desc: Window/context/input library
#version: 3.4
#name: glfw

source "$(dirname "$0")/common.sh"
skip_if_installed "glfw3" "$INSTALL_PREFIX/lib/libglfw3.a" "glfw"

wget https://github.com/glfw/glfw/archive/refs/tags/3.4.zip -O glfw-3.4.zip
unzip -o glfw-3.4.zip
cmake -S glfw-3.4 -B build-glfw -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DGLFW_BUILD_EXAMPLES=OFF -DGLFW_BUILD_TESTS=OFF -DGLFW_BUILD_DOCS=OFF
cmake --build build-glfw --parallel
cmake --install build-glfw
rm -r build-glfw glfw-3.4 glfw-3.4.zip
echo "Test: pkg-config --libs glfw3"

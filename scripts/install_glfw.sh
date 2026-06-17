#!/bin/bash
set -e
#deps: none
#desc: Window/context/input library
#version: 3.4
#name: glfw

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists glfw3 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libglfw3.a" ] ); then
    echo "[SKIPPED] glfw already installed"; exit 0
fi

wget https://github.com/glfw/glfw/archive/refs/tags/3.4.zip -O glfw-3.4.zip
unzip -o glfw-3.4.zip
cmake -S glfw-3.4 -B build-glfw -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DGLFW_BUILD_EXAMPLES=OFF -DGLFW_BUILD_TESTS=OFF -DGLFW_BUILD_DOCS=OFF
cmake --build build-glfw --parallel
cmake --install build-glfw
rm -r build-glfw glfw-3.4 glfw-3.4.zip
echo "Test: pkg-config --libs glfw3"

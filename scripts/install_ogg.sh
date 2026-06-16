#!/bin/bash
#deps: none
#desc: Ogg audio container
#version: 1.3.6
#name: ogg

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists ogg 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libogg.a" ]; then
    echo "[SKIPPED] ogg already installed"; exit 0
fi

wget https://downloads.xiph.org/releases/ogg/libogg-1.3.6.zip
unzip libogg-1.3.6.zip
cmake -S libogg-1.3.6 -B build_ogg -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DINSTALL_DOCS=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_FRAMEWORK=OFF -DBUILD_TESTING=OFF
cmake --build build_ogg --parallel
cmake --install build_ogg
rm -r libogg-1.3.6 build_ogg libogg-1.3.6.zip
echo "Test: pkg-config --cflags --libs ogg"
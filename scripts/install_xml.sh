#!/bin/bash
set -e
#deps: none
#desc: XML parsing library (Expat)
#version: 2.6.4
#name: xml

INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists expat 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libexpat.a" ] ); then
    echo "[SKIPPED] xml already installed"; exit 0
fi

wget https://github.com/libexpat/libexpat/releases/download/R_2_6_4/expat-2.6.4.tar.gz -O expat-2.6.4.tar.gz
tar -xf expat-2.6.4.tar.gz
cmake -S expat-2.6.4 -B build-xml -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_TOOLS=OFF
cmake --build build-xml --parallel
cmake --install build-xml
rm -r build-xml expat-2.6.4 expat-2.6.4.tar.gz
echo "Test: pkg-config --cflags --libs expat"

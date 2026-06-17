#!/bin/bash
set -e
#deps: none
#desc: WebP image format library
#version: 1.5.0
#name: libwebp

INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists libwebp 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libwebp.a" ] ); then
    echo "[SKIPPED] libwebp already installed"; exit 0
fi

wget https://github.com/webmproject/libwebp/archive/refs/tags/v1.5.0.tar.gz -O libwebp-1.5.0.tar.gz
tar -xf libwebp-1.5.0.tar.gz
cmake -S libwebp-1.5.0 -B build-libwebp -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DWEBP_BUILD_ANIM_UTILS=OFF -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF -DWEBP_BUILD_GIF2WEBP=OFF -DWEBP_BUILD_IMG2WEBP=OFF -DWEBP_BUILD_VWEBP=OFF -DWEBP_BUILD_WEBPINFO=OFF -DWEBP_BUILD_WEBPMUX=OFF -DWEBP_BUILD_EXTRAS=OFF
cmake --build build-libwebp --parallel
cmake --install build-libwebp
rm -r build-libwebp libwebp-1.5.0 libwebp-1.5.0.tar.gz
echo "Test: pkg-config --cflags --libs libwebp"

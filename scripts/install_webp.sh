#!/bin/bash
set -e
#deps: none
#desc: WebP image format library
#version: 1.5.0
#name: webp

source "$(dirname "$0")/common.sh"
skip_if_installed "libwebp" "$INSTALL_PREFIX/lib/libwebp.a" "webp"

wget https://github.com/webmproject/libwebp/archive/refs/tags/v1.5.0.tar.gz -O libwebp-1.5.0.tar.gz
tar -xf libwebp-1.5.0.tar.gz
cmake -S libwebp-1.5.0 -B build-libwebp -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DWEBP_BUILD_ANIM_UTILS=OFF -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF -DWEBP_BUILD_GIF2WEBP=OFF -DWEBP_BUILD_IMG2WEBP=OFF -DWEBP_BUILD_VWEBP=OFF -DWEBP_BUILD_WEBPINFO=OFF -DWEBP_BUILD_WEBPMUX=ON -DWEBP_BUILD_EXTRAS=OFF
cmake --build build-libwebp --parallel
cmake --install build-libwebp

# Create proper pkg-config file with both webp and webpdemux
cat > "$INSTALL_PREFIX/lib/pkgconfig/libwebp.pc" <<EOF
prefix=$INSTALL_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libwebp
Description: Library for the WebP graphics format
Version: 1.5.0
Requires.private: libsharpyuv
Cflags: -I\${includedir}
Libs: -L\${libdir} -lwebp -lwebpdemux
Libs.private: -lsharpyuv
EOF

rm -r build-libwebp libwebp-1.5.0 libwebp-1.5.0.tar.gz
echo "Test: pkg-config --cflags --libs libwebp"

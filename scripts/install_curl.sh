#!/bin/bash
set -e
#deps: zlib zstd brotli bz2
#desc: URL transfer library
#version: 8.19.0
#name: curl

source "$(dirname "$0")/common.sh"
skip_if_installed "libcurl" "$INSTALL_PREFIX/lib/libcurl.a" "curl"

wget https://github.com/curl/curl/releases/download/curl-8_19_0/curl-8.19.0.zip
unzip -o curl-8.19.0.zip
cmake -S curl-8.19.0 -B build-curl -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DZLIB_LIBRARY="$INSTALL_PREFIX"/lib/libzs.a -DBUILD_CURL_EXE=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF -DCURL_BUILD_TESTING=OFF -DCURL_USE_LIBPSL=OFF -DUSE_NGHTTP2=OFF -DUSE_LIBIDN2=OFF -DCURL_USE_LIBSSH2=OFF -DBUILD_LIBCURL_DOCS=OFF -DENABLE_CURL_MANUAL=OFF -DBUILD_MISC_DOCS=OFF -DCURL_TARGET_WINDOWS_VERSION=0x0A00
cmake --build build-curl --parallel
cmake --install build-curl
rm -r build-curl curl-8.19.0 curl-8.19.0.zip
echo "Test: pkg-config --libs --cflags libcurl"

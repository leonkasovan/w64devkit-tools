#!/bin/bash
set -e
#deps: zlib, zstd, brotli
#desc: URL transfer library and tool (libcurl + curl.exe)
#version: 8.19.0
#name: curl

source "$(dirname "$0")/common.sh"
# Merged from install_curl.sh + install_curltool.sh: one build installs both
# libcurl (lib/headers/pkg-config) and curl.exe. curl.exe is the skip marker
# since only this script produces it.
skip_if_installed "curl-tool" "$INSTALL_PREFIX/bin/curl.exe" "curl"

wget https://github.com/curl/curl/releases/download/curl-8_19_0/curl-8.19.0.zip
unzip -o curl-8.19.0.zip
cmake -S curl-8.19.0 -B build-curl -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DZLIB_LIBRARY="$INSTALL_PREFIX"/lib/libzs.a -DBUILD_CURL_EXE=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DCURL_USE_SCHANNEL=ON -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF -DCURL_BUILD_TESTING=OFF -DCURL_USE_LIBPSL=OFF -DUSE_NGHTTP2=OFF -DUSE_LIBIDN2=OFF -DCURL_USE_LIBSSH2=OFF -DBUILD_LIBCURL_DOCS=OFF -DENABLE_CURL_MANUAL=OFF -DBUILD_MISC_DOCS=OFF -DCURL_TARGET_WINDOWS_VERSION=0x0A00
cmake --build build-curl --parallel
cmake --install build-curl
mkdir -p "$INSTALL_PREFIX/bin"
cp -f build-curl/src/curl.exe "$INSTALL_PREFIX/bin/"
rm -r build-curl curl-8.19.0 curl-8.19.0.zip
echo "Test: pkg-config --libs --cflags libcurl"
echo "Test: \"$INSTALL_PREFIX\"/bin/curl.exe --version"

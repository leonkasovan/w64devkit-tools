#!/bin/bash
set -e
#deps: bz2, zlib
#desc: PCRE2 regular expression library
#version: 10.45
#name: pcre2

INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists libpcre2-8 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libpcre2-8.a" ] ); then
    echo "[SKIPPED] pcre2 already installed"; exit 0
fi

wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.45/pcre2-10.45.tar.gz -O pcre2-10.45.tar.gz
tar -xf pcre2-10.45.tar.gz
cmake -S pcre2-10.45 -B build-pcre2 -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DPCRE2_BUILD_PCRE2_8=ON -DPCRE2_BUILD_PCRE2_16=OFF -DPCRE2_BUILD_PCRE2_32=OFF -DPCRE2_BUILD_TESTS=OFF
cmake --build build-pcre2 --parallel
cmake --install build-pcre2
rm -r build-pcre2 pcre2-10.45 pcre2-10.45.tar.gz
echo "Test: pkg-config --cflags --libs libpcre2-8"

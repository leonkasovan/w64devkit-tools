#!/bin/bash
set -e
#deps: bz2, zlib
#desc: PCRE2 regular expression library
#version: 10.45
#name: pcre2

source "$(dirname "$0")/common.sh"
skip_if_installed "libpcre2-8" "$INSTALL_PREFIX/lib/libpcre2-8.a" "pcre2"

wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.45/pcre2-10.45.tar.gz -O pcre2-10.45.tar.gz
tar -xf pcre2-10.45.tar.gz
cmake -S pcre2-10.45 -B build-pcre2 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DPCRE2_BUILD_PCRE2_8=ON -DPCRE2_BUILD_PCRE2_16=OFF -DPCRE2_BUILD_PCRE2_32=OFF -DPCRE2_BUILD_TESTS=OFF
cmake --build build-pcre2 --parallel
cmake --install build-pcre2
# Fix .pc file for MinGW static linking (cmake omits -static in Libs.private)
sed -i 's/^Libs.private:.*/Libs.private: -static/' "$INSTALL_PREFIX/lib/pkgconfig/libpcre2-8.pc"
rm -r build-pcre2 pcre2-10.45 pcre2-10.45.tar.gz
echo "Test: pkg-config --cflags --libs libpcre2-8"

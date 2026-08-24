#!/bin/bash
set -e
#deps: none
#desc: XML/HTML formatter and validator (xmllint, from libxml2)
#version: 2.15.3
#name: xmllint

source "$(dirname "$0")/common.sh"
skip_if_installed "libxml-2.0" "$INSTALL_PREFIX/bin/xmllint.exe" "xmllint"

wget https://download.gnome.org/sources/libxml2/2.15/libxml2-2.15.3.tar.xz -O libxml2-2.15.3.tar.xz
tar -xf libxml2-2.15.3.tar.xz
cmake -S libxml2-2.15.3 -B build-xmllint \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DBUILD_SHARED_LIBS=OFF \
    -DLIBXML2_WITH_PROGRAMS=ON \
    -DLIBXML2_WITH_HTML=ON \
    -DLIBXML2_WITH_OUTPUT=ON \
    -DLIBXML2_WITH_TESTS=OFF \
    -DLIBXML2_WITH_DOCS=OFF \
    -DLIBXML2_WITH_CATALOG=OFF \
    -DLIBXML2_WITH_ICONV=OFF \
    -DLIBXML2_WITH_ICU=OFF \
    -DLIBXML2_WITH_LZMA=OFF \
    -DLIBXML2_WITH_ZLIB=OFF \
    -DLIBXML2_WITH_PYTHON=OFF
cmake --build build-xmllint --parallel
cmake --install build-xmllint
rm -rf build-xmllint libxml2-2.15.3 libxml2-2.15.3.tar.xz
echo "Test: \"$INSTALL_PREFIX\"/bin/xmllint.exe --version"

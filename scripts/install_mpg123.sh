#!/bin/bash
set -e
#deps: none
#desc: MPEG audio decoder
#version: 1.33.5
#name: mpg123

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists libmpg123 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libmpg123.a" ] ); then
    echo "[SKIPPED] mpg123 already installed"; exit 0
fi

wget https://www.mpg123.de/download/mpg123-1.33.5.tar.bz2 -O mpg123-1.33.5.tar.bz2 || \
wget http://www.mpg123.de/download/mpg123-1.33.5.tar.bz2 -O mpg123-1.33.5.tar.bz2
tar -xjf mpg123-1.33.5.tar.bz2
(
  cd mpg123-1.33.5
  PATH="$INSTALL_PREFIX/bin:$PATH" ./configure --prefix="$INSTALL_PREFIX" --enable-static --disable-shared --disable-components --enable-libmpg123 --with-gnu-ld --host=i686-w64-mingw32
  make -j8
  make install
)
rm -r mpg123-1.33.5 mpg123-1.33.5.tar.bz2
echo "Test: pkg-config --cflags --libs libmpg123"

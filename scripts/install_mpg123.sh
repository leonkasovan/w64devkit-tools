#!/bin/bash
#deps: none
#desc: MPEG audio decoder
#version: 1.33.5
#name: mpg123

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists libmpg123 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libmpg123.a" ]; then
    echo "[SKIPPED] mpg123 already installed"; exit 0
fi

wget https://sourceforge.net/projects/mpg123/files/mpg123/1.33.5/mpg123-1.33.5.tar.bz2/download -O mpg123-1.33.5.tar.bz2
tar -xjf mpg123-1.33.5.tar.bz2
(
  cd mpg123-1.33.5
  ./configure --prefix="$INSTALL_PREFIX" --enable-static --disable-shared --disable-components --enable-libmpg123
  make -j8
  make install
)
rm -r mpg123-1.33.5 mpg123-1.33.5.tar.bz2
echo "Test: pkg-config --cflags --libs libmpg123"
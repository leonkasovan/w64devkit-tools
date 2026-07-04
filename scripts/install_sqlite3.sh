#!/bin/bash
set -e
#deps: none
#desc: Embedded SQL database engine
#version: 3.50.0
#name: sqlite3

source "$(dirname "$0")/common.sh"
skip_if_installed "sqlite3" "$INSTALL_PREFIX/lib/libsqlite3.a" "sqlite3"

wget https://www.sqlite.org/2025/sqlite-autoconf-3500000.tar.gz -O sqlite3-3.50.0.tar.gz
tar -xf sqlite3-3.50.0.tar.gz
(
  cd sqlite-autoconf-3500000
  export PATH="$INSTALL_PREFIX/bin:$PATH"
  ./configure --prefix="$INSTALL_PREFIX" --enable-static --disable-shared
  make -j8
  make install
)
rm -r sqlite-autoconf-3500000 sqlite3-3.50.0.tar.gz
echo "Test: pkg-config --cflags --libs sqlite3"

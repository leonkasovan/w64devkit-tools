#!/bin/bash
#deps: none
#desc: Bzip2 compression
#version: 1.0.8
#name: bz2

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists bzip2 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libbz2.a" ]; then
    echo "[SKIPPED] bz2 already installed"; exit 0
fi

wget https://github.com/libarchive/bzip2/archive/refs/tags/bzip2-1.0.8.zip -O bzip2-1.0.8.zip
unzip bzip2-1.0.8.zip
(
  cd bzip2-bzip2-1.0.8
  make libbz2.a
  cp -f libbz2.a "$INSTALL_PREFIX"/lib/
  cp -f bzlib.h "$INSTALL_PREFIX"/include/
)
rm -r bzip2-bzip2-1.0.8 bzip2-1.0.8.zip
echo "Test: ls "$INSTALL_PREFIX"/lib/libbz2.a "$INSTALL_PREFIX"/include/bzlib.h"
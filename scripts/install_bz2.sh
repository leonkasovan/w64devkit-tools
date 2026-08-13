#!/bin/bash
set -e
#deps: none
#desc: Bzip2 compression
#version: 1.0.8
#name: bz2

source "$(dirname "$0")/common.sh"
skip_if_installed "bzip2" "$INSTALL_PREFIX/lib/libbz2.a" "bz2"

wget https://github.com/libarchive/bzip2/archive/refs/tags/bzip2-1.0.8.zip -O bzip2-1.0.8.zip
unzip -o bzip2-1.0.8.zip
(
  cd bzip2-bzip2-1.0.8
  make libbz2.a
  mkdir -p "$INSTALL_PREFIX"/lib "$INSTALL_PREFIX"/include
  cp -f libbz2.a "$INSTALL_PREFIX"/lib/
  cp -f bzlib.h "$INSTALL_PREFIX"/include/
)
rm -r bzip2-bzip2-1.0.8 bzip2-1.0.8.zip
echo "Test: ls "$INSTALL_PREFIX"/lib/libbz2.a "$INSTALL_PREFIX"/include/bzlib.h"

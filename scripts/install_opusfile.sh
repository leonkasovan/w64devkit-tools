#!/bin/bash
set -e
#deps: opus, ogg
#desc: Opus audio file library
#version: 0.12
#name: opusfile

source "$(dirname "$0")/common.sh"
skip_if_installed "opusfile" "$INSTALL_PREFIX/lib/libopusfile.a" "opusfile"

wget https://github.com/xiph/opusfile/releases/download/v0.12/opusfile-0.12.zip -O opusfile-0.12.zip
unzip -o opusfile-0.12.zip
(
  cd opusfile-0.12
  mkdir -p /tmp
  # Cache tool paths for autotools (avoids PATH format issues with MSYS2)
  export ac_cv_path_GREP="$(command -v grep)"
  export ac_cv_path_EGREP="$(command -v grep) -E"
  export ac_cv_path_FGREP="$(command -v grep) -F"
  export ac_cv_prog_AWK="$(command -v awk)"
  export ac_cv_path_SED="$(command -v sed)"
  export LD="$(command -v ld)"
  export AR="$(command -v ar)"
  export RANLIB="$(command -v ranlib)"
  export STRIP="$(command -v strip)"
  export NM="$(command -v nm)"
  export PKG_CONFIG="$(command -v pkg-config)"
  export DEPS_CFLAGS="-I$INSTALL_PREFIX/include -I$INSTALL_PREFIX/include/opus"
  export DEPS_LIBS="-L$INSTALL_PREFIX/lib -lopus -logg"
  ./configure CC=gcc --build=$(gcc -dumpmachine) --host=$(gcc -dumpmachine) --disable-maintainer-mode --disable-http --disable-examples --disable-doc --disable-shared --prefix="$INSTALL_PREFIX" CFLAGS="-O2 -DNDEBUG" LDFLAGS="-s"
  make -j8
  make install
)
rm -r opusfile-0.12 opusfile-0.12.zip
echo "Test: ls $INSTALL_PREFIX/lib/libopusfile.a $INSTALL_PREFIX/include/opus/opusfile.h"

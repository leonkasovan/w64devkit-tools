#!/bin/bash
set -e
#deps: none
#desc: MPEG audio decoder
#version: 1.33.5
#name: mpg123

source "$(dirname "$0")/common.sh"
skip_if_installed "libmpg123" "$INSTALL_PREFIX/lib/libmpg123.a" "mpg123"

wget http://www.mpg123.de/download/mpg123-1.33.5.tar.bz2 -O mpg123-1.33.5.tar.bz2
tar -xjf mpg123-1.33.5.tar.bz2
(
  cd mpg123-1.33.5
  mkdir -p /tmp
  # Cache tool paths for autotools (avoids PATH format issues with MSYS2)
  export ac_cv_path_GREP="$(command -v grep)"
  export ac_cv_path_EGREP="$(command -v grep) -E"
  export ac_cv_path_FGREP="$(command -v grep) -F"
  export ac_cv_prog_AWK="$(command -v awk)"
  export ac_cv_path_SED="$(command -v sed)"
  # Set LD and other binutils env vars directly (libtool checks $LD first)
  export LD="$(command -v ld)"
  export AR="$(command -v ar)"
  export AS="$(command -v as)"
  export DLLTOOL="$(command -v dlltool)"
  export NM="$(command -v nm)"
  export OBJDUMP="$(command -v objdump)"
  export RANLIB="$(command -v ranlib)"
  export STRIP="$(command -v strip)"
  ./configure CC=gcc --build=$(gcc -dumpmachine) --host=$(gcc -dumpmachine) --prefix="$INSTALL_PREFIX" --enable-static --disable-shared --disable-components --enable-libmpg123 --with-gnu-ld
  make -j8
  make install
)
rm -r mpg123-1.33.5 mpg123-1.33.5.tar.bz2
echo "Test: pkg-config --cflags --libs libmpg123"

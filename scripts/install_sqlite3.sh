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
  ./configure CC=gcc --build=$(gcc -dumpmachine) --host=$(gcc -dumpmachine) --prefix="$INSTALL_PREFIX" --enable-static --disable-shared --disable-readline
  make -j8
  # Manual install — autotools 'install -m' fails on MinGW
  mkdir -p "$INSTALL_PREFIX/lib" "$INSTALL_PREFIX/include"
  cp libsqlite3.a "$INSTALL_PREFIX/lib/"
  cp sqlite3.h "$INSTALL_PREFIX/include/"
  cp sqlite3ext.h "$INSTALL_PREFIX/include/"
  # Generate pkg-config file
  mkdir -p "$INSTALL_PREFIX/lib/pkgconfig"
  cat > "$INSTALL_PREFIX/lib/pkgconfig/sqlite3.pc" <<EOF
prefix=$INSTALL_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: sqlite3
Description: SQL database engine
Version: 3.50.0
Libs: -L\${libdir} -lsqlite3 -lz
Cflags: -I\${includedir} -DSQLITE_THREADSAFE=1
EOF
)
rm -rf sqlite-autoconf-3500000 sqlite3-3.50.0.tar.gz
echo "Test: pkg-config --cflags --libs sqlite3"

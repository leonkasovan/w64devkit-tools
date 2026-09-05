#!/bin/bash
set -e
#deps: zlib
#desc: File type identification utility (file.exe, libmagic)
#version: 5.46
#name: file

source "$(dirname "$0")/common.sh"
skip_if_installed "libmagic" "$INSTALL_PREFIX/bin/file.exe" "file"

# MinGW requires libgnurx (GNU regex) to build file(1). Build/install a
# static copy into $INSTALL_PREFIX if not already present.
if [ "$FORCE_UPDATE" = "true" ] || [ ! -f "$INSTALL_PREFIX/lib/libgnurx.a" -a ! -f "$INSTALL_PREFIX/lib/libregex.a" ]; then
  echo "libgnurx not found in $INSTALL_PREFIX/lib — building static libgnurx..."
  GNURX_VER="2.5.1"
  GNURX_TARBALL="mingw-libgnurx-${GNURX_VER}-src.tar.gz"
  if [ ! -f "$GNURX_TARBALL" ] || [ "$(od -An -N2 -tx1 "$GNURX_TARBALL" 2>/dev/null | tr -d ' \n')" != "1f8b" ]; then
    rm -f "$GNURX_TARBALL"
    # Primary: SourceForge canonical tarball
    wget "https://downloads.sourceforge.net/project/mingw/Other/UserContributed/regex/mingw-regex-2.5.1/${GNURX_TARBALL}" -O "$GNURX_TARBALL" || \
    wget "http://download.sourceforge.net/mingw/Other/UserContributed/regex/mingw-regex-2.5.1/${GNURX_TARBALL}" -O "$GNURX_TARBALL" || \
    # Fallback: WohlSoft mirror (same sources, CMake+Makefile)
    wget "https://github.com/WohlSoft/libgnurx/archive/refs/heads/master.tar.gz" -O "$GNURX_TARBALL"
  fi
  if [ "$(od -An -N2 -tx1 "$GNURX_TARBALL" | tr -d ' \n')" != "1f8b" ]; then
    echo "error: $GNURX_TARBALL is not a gzip archive (download failed?)"
    exit 1
  fi
  rm -rf "mingw-libgnurx-${GNURX_VER}" libgnurx-master
  tar -xf "$GNURX_TARBALL"
  # SourceForge tarball extracts to mingw-libgnurx-2.5.1/, GitHub mirror to libgnurx-master/
  GNURX_SRC=""
  if [ -d "mingw-libgnurx-${GNURX_VER}" ]; then GNURX_SRC="mingw-libgnurx-${GNURX_VER}"; else GNURX_SRC="libgnurx-master"; fi
  (
    cd "$GNURX_SRC"
    # regex.c is an amalgamation that #includes regex_internal.c/regcomp.c/regexec.c
    # — compile only it. -std=gnu89 avoids C23 'false'/'true' keyword clash in
    # regex_internal.h (2007 glibc code), -I. lets <regex.h> resolve to the
    # local header.
    gcc -std=gnu89 -O2 -DNDEBUG -DREGEX_MALLOC -I. -c regex.c -o regex.o
    ar rcs libgnurx.a regex.o
    ranlib libgnurx.a
    mkdir -p "$INSTALL_PREFIX/lib" "$INSTALL_PREFIX/include"
    cp -f libgnurx.a "$INSTALL_PREFIX/lib/libgnurx.a"
    cp -f libgnurx.a "$INSTALL_PREFIX/lib/libregex.a"
    # import lib for configure checks that try -lgnurx.dll
    cp -f libgnurx.a "$INSTALL_PREFIX/lib/libgnurx.dll.a" 2>/dev/null || true
    cp -f regex.h "$INSTALL_PREFIX/include/regex.h" 2>/dev/null || cp -f regex.h "$INSTALL_PREFIX/include/gnurx/regex.h" 2>/dev/null || true
    # also provide header at top-level if source uses subdir
    if [ ! -f "$INSTALL_PREFIX/include/regex.h" ] && [ -f "regex.h" ]; then
      cp -f regex.h "$INSTALL_PREFIX/include/"
    fi
  )
  rm -rf "$GNURX_SRC" "$GNURX_TARBALL"
  echo "libgnurx installed to $INSTALL_PREFIX/lib/libgnurx.a"
fi

FILE_VER="5.46"
wget "https://astron.com/pub/file/file-${FILE_VER}.tar.gz" -O "file-${FILE_VER}.tar.gz"
# sanity check: should be a gzip archive (starts with 1f 8b)
if [ "$(od -An -N2 -tx1 "file-${FILE_VER}.tar.gz" | tr -d ' \n')" != "1f8b" ]; then
    echo "error: file-${FILE_VER}.tar.gz is not a gzip archive (download failed?)"
    exit 1
fi
tar -xf "file-${FILE_VER}.tar.gz"
# Fix mingw-w64 64-bit time_t (long long, 8B) vs timespec tv_sec (long, 4B)
# mismatch that makes -Wincompatible-pointer-types an error with -Werror:
#   readcdf.c:239  cdf_ctime(&ts.tv_sec, ...)  long* -> time_t*
# Use compound literal to convert value, not pointer type.
for f in "file-${FILE_VER}/src/readcdf.c" "file-${FILE_VER}/src/cdf.c" "file-${FILE_VER}/src/cdf_time.c"; do
  [ -f "$f" ] && sed -i 's/cdf_ctime(&ts\.tv_sec/cdf_ctime(\&(time_t){ts.tv_sec}/g' "$f"
done
(
  cd "file-${FILE_VER}"
  mkdir -p /tmp
  # libtool fails if SHELL contains spaces (Git's bash at C:/Program Files/...),
  # force w64devkit's sh which has no spaces.
  if [ -x "C:/w64devkit/bin/sh.exe" ]; then
    export SHELL="C:/w64devkit/bin/sh.exe"
    export CONFIG_SHELL="C:/w64devkit/bin/sh.exe"
  elif [ -x "$INSTALL_PREFIX/bin/sh.exe" ]; then
    export SHELL="$INSTALL_PREFIX/bin/sh.exe"
    export CONFIG_SHELL="$INSTALL_PREFIX/bin/sh.exe"
  elif [ -x "$INSTALL_PREFIX/bin/bash.exe" ]; then
    export SHELL="$INSTALL_PREFIX/bin/bash.exe"
    export CONFIG_SHELL="$INSTALL_PREFIX/bin/bash.exe"
  fi
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
  # Make sure file's configure finds the just-built libgnurx in $INSTALL_PREFIX
  export CPPFLAGS="-I$INSTALL_PREFIX/include"
  export LDFLAGS="-L$INSTALL_PREFIX/lib -s"
  ./configure \
    --prefix="$INSTALL_PREFIX" \
    --build="$(gcc -dumpmachine)" \
    --host="$(gcc -dumpmachine)" \
    --enable-static \
    --disable-shared \
    CC="gcc" \
    CFLAGS="-O2 -DNDEBUG -I$INSTALL_PREFIX/include -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration" \
    LDFLAGS="-L$INSTALL_PREFIX/lib -s"
  make -j"$(nproc)"
  make install
)
rm -rf "file-${FILE_VER}" "file-${FILE_VER}.tar.gz"
echo "Test: \"$INSTALL_PREFIX\"/bin/file.exe --version"

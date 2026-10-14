#!/bin/bash
set -e
#deps: none
#desc: GNU grep, egrep, fgrep (built from source)
#version: 3.11
#name: grep

source "$(dirname "$0")/common.sh"
skip_if_installed "grep" "$INSTALL_PREFIX/bin/grep.exe" "GNU grep"

GREP_VER="3.11"
wget "https://ftp.gnu.org/gnu/grep/grep-${GREP_VER}.tar.xz" -O "grep-${GREP_VER}.tar.xz"
# sanity check: should be an xz archive (starts with 37 7a)
if [ "$(od -An -N2 -tx1 "grep-${GREP_VER}.tar.xz" | tr -d ' \n')" != "377a" ]; then
    echo "error: grep-${GREP_VER}.tar.xz is not an xz archive (download failed?)"
    exit 1
fi
tar -xf "grep-${GREP_VER}.tar.xz"
(
  cd "grep-${GREP_VER}"
  # Cache tool paths for autotools (avoids PATH format issues with MSYS2)
  export CC="gcc"
  export LD="$(command -v ld)"
  export AR="$(command -v ar)"
  export RANLIB="$(command -v ranlib)"
  export STRIP="$(command -v strip)"
  export NM="$(command -v nm)"
  ./configure \
    --prefix="$INSTALL_PREFIX" \
    --build="$(gcc -dumpmachine)" \
    --host="$(gcc -dumpmachine)" \
    CC="gcc" \
    CFLAGS="-O2 -DNDEBUG" \
    LDFLAGS="-s"
  make -j"$(nproc)"
  # Manual install — autotools 'install -m' fails on MinGW
  mkdir -p "$INSTALL_PREFIX/bin"
  cp -f src/grep.exe "$INSTALL_PREFIX/bin/grep.exe"
  cp -f src/egrep.exe "$INSTALL_PREFIX/bin/egrep.exe" 2>/dev/null || true
  cp -f src/fgrep.exe "$INSTALL_PREFIX/bin/fgrep.exe" 2>/dev/null || true
  cp -f src/bgrep.exe "$INSTALL_PREFIX/bin/bgrep.exe" 2>/dev/null || true
)
rm -rf "grep-${GREP_VER}" "grep-${GREP_VER}.tar.xz"
echo "Test: \"$INSTALL_PREFIX\"/bin/grep.exe --version"

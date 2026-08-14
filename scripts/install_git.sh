#!/bin/bash
set -e
#deps: zlib, curl
#desc: Distributed version control system (git.exe)
#version: 2.55.0
#name: git

source "$(dirname "$0")/common.sh"
skip_if_installed "git" "$INSTALL_PREFIX/bin/git.exe" "git"

# git's Makefile auto-detects the platform from `uname -s`, but w64devkit's
# uname reports "Windows_NT", which matches no config.mak.uname branch (it
# would fall into the MSVC/Windows branch). Force the MinGW branch via
# uname_S=MINGW on the make command line: that overrides config.mak.uname's
# `uname_S := $(shell uname -s)`, whereas the same assignment in config.mak is
# read too late to steer branch selection.
# Tool paths are pinned explicitly (the app passes a Windows PATH that busybox
# ash can't parse, see install_nasm.sh).
find_tool() {
    if [ -x "$INSTALL_PREFIX/bin/$1" ]; then
        echo "$INSTALL_PREFIX/bin/$1"
    else
        command -v "$1" 2>/dev/null || echo "$1"
    fi
}

GCC="$(find_tool gcc)"
SH="$(find_tool sh)"
export SHELL="$SH"
# The MinGW branch keys off MSYSTEM to select the x86_64 linker flags.
export MSYSTEM=MINGW64
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib/pkgconfig"

wget https://github.com/git/git/archive/refs/tags/v2.55.0.tar.gz -O git-2.55.0.tar.gz
# sanity check: GitHub can return an HTML error page instead of the file
if [ "$(od -An -N2 -tx1 git-2.55.0.tar.gz | tr -d ' \n')" != "1f8b" ]; then
    echo "error: git-2.55.0.tar.gz is not a gzip archive (download failed?)"
    exit 1
fi
tar -xf git-2.55.0.tar.gz

(
  cd git-2.55.0
  # git's Makefile -includes config.mak AFTER config.mak.uname, so this cannot
  # steer the platform branch; uname_S=MINGW on the make command line does.
  cat > config.mak <<EOF
uname_S = MINGW
prefix = $INSTALL_PREFIX
CC = $GCC
AR = $(find_tool ar)
RANLIB = $(find_tool ranlib)
STRIP = $(find_tool strip)
NM = $(find_tool nm)
INSTALL = $(find_tool install)
# -O coff: without it windres guesses format from the .res output name and
# emits a raw resource blob that ld rejects at link time
RC = $(find_tool windres) -O coff
SHELL_PATH = $SH
ZLIB_PATH = $INSTALL_PREFIX
CURL_CONFIG = $INSTALL_PREFIX/bin/curl-config
CURL_CFLAGS = -I$INSTALL_PREFIX/include
CURL_LDFLAGS = $("$INSTALL_PREFIX/bin/curl-config" --static-libs)
# Rust is built by default since 2.55 but w64devkit has no cargo toolchain
NO_RUST = YesPlease
NO_GETTEXT = YesPlease
NO_ICONV = YesPlease
NO_PERL = YesPlease
NO_PYTHON = YesPlease
NO_TCLTK = YesPlease
NO_OPENSSL = YesPlease
NO_EXPAT = YesPlease
# The MinGW branch sets USE_LIBPCRE, which would require libpcre2; clear it.
# MinGW-w64 has no system regex.h, so use git's bundled compat/regex too.
USE_LIBPCRE =
NO_REGEX = YesPlease
EOF
  make -j"$(nproc)" uname_S=MINGW
  make install uname_S=MINGW
)
rm -r git-2.55.0 git-2.55.0.tar.gz
echo "Test: \"$INSTALL_PREFIX\"/bin/git.exe --version"

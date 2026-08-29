#!/bin/bash
set -e
#deps: none
#desc: 7-Zip file archiver (7z.exe, built from source)
#version: 26.02
#name: 7z

source "$(dirname "$0")/common.sh"
skip_if_installed "7z" "$INSTALL_PREFIX/bin/7z.exe" "7z"

wget https://github.com/ip7z/7zip/releases/download/26.02/7z2602-src.tar.xz
tar -xf 7z2602-src.tar.xz

# The makefiles pick busybox-style `mkdir -p`/`rm -f` only when IS_MINGW + MSYSTEM
# are set (w64devkit is MinGW without MSYSTEM otherwise). USE_ASM needs jwasm/asmc
# which w64devkit doesn't ship, so build the portable C paths; CFLAGS_WARN_WALL
# clears -Werror so warnings from newer gcc don't fail the build.
export MSYSTEM=MINGW64
case "$(gcc -dumpmachine)" in
  i686*|i386*) CMPL=cmpl_gcc_x86.mak; PLATFORM=x86 ;;
  *)           CMPL=cmpl_gcc_x64.mak; PLATFORM=x64 ;;
esac
(
  cd CPP/7zip/Bundles/Alone2
  make USE_ASM= CFLAGS_WARN_WALL= CFLAGS_ADD="-O2 -DNDEBUG" LDFLAGS_ADD="-s" -f ../../$CMPL -j"$(nproc)"
)
mkdir -p "$INSTALL_PREFIX/bin"
cp -f "CPP/7zip/Bundles/Alone2/b/g_$PLATFORM/7zz.exe" "$INSTALL_PREFIX/bin/7z.exe"
rm -r Asm C CPP DOC 7z2602-src.tar.xz
echo "Test: \"$INSTALL_PREFIX\"/bin/7z.exe -version"

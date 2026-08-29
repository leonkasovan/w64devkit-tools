#!/bin/bash
set -e
#deps: none
#desc: FFmpeg audio/video libraries
#version: 7.1
#name: ffmpeg

source "$(dirname "$0")/common.sh"
skip_if_installed "libavutil" "$INSTALL_PREFIX/lib/libavutil.a" "ffmpeg"

#check if ffmpeg-7.1.zip already exists and is valid
if [ -f "ffmpeg-7.1.zip" ]; then
  echo "ffmpeg-7.1.zip already exists, skipping download."
else
  wget https://github.com/FFmpeg/FFmpeg/archive/refs/heads/release/7.1.zip -O ffmpeg-7.1.zip
fi

# check if FFmpeg-release-7.1 directory already exists and is valid
if [ -d "FFmpeg-release-7.1" ]; then
  echo "FFmpeg-release-7.1 directory already exists, skipping extraction."
else
  unzip -o ffmpeg-7.1.zip
fi

(
  cd FFmpeg-release-7.1
  # Cache tool paths for configure (avoids PATH format issues with MSYS2)
  export CC="gcc"
  export LD="$(command -v ld)"
  export AR="$(command -v ar)"
  export AS="$(command -v as)"
  export RANLIB="$(command -v ranlib)"
  export STRIP="$(command -v strip)"
  export NM="$(command -v nm)"
  ./configure \
    --prefix="$INSTALL_PREFIX" \
    --enable-static \
    --disable-shared \
    --disable-programs \
    --disable-doc \
    --disable-network \
    --disable-debug \
    --enable-small \
    --disable-x86asm \
    --target-os=mingw32 \
    --arch="$(gcc -dumpmachine | cut -d- -f1)" \
    --extra-cflags="-O2 -DNDEBUG -I$INSTALL_PREFIX/include" \
    --extra-ldflags="-s -L$INSTALL_PREFIX/lib"
  make V=1 -j8
  make V=1 install
)
rm -r FFmpeg-release-7.1 ffmpeg-7.1.zip
echo "Test: pkg-config --cflags --libs libavutil"

#!/bin/bash
#deps: ogg
#desc: FLAC audio codec
#version: 1.5.0
#name: flac

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"

if pkg-config --exists flac 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libFLAC.a" ]; then
    echo "[SKIPPED] flac already installed"; exit 0
fi

wget https://ftp.osuosl.org/pub/xiph/releases/flac/flac-1.5.0.tar.xz
tar -xJf flac-1.5.0.tar.xz
cmake -S flac-1.5.0 -B build_flac -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DBUILD_CXXLIBS=OFF -DBUILD_PROGRAMS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DBUILD_DOCS=OFF -DINSTALL_MANPAGES=OFF -DWITH_OGG=ON -DENABLE_MULTITHREADING=OFF
cmake --build build_flac --parallel
cmake --install build_flac
rm -r build_flac flac-1.5.0 flac-1.5.0.tar.xz
echo "Test: pkg-config --cflags --libs flac"
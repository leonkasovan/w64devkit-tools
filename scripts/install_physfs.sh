#!/bin/bash
set -e
#deps: none
#desc: Virtual filesystem abstraction (PhysicsFS)
#version: 3.2.0
#name: physfs

INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists physfs 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libphysfs.a" ] ); then
    echo "[SKIPPED] physfs already installed"; exit 0
fi

wget https://github.com/icculus/physfs/archive/refs/tags/release-3.2.0.tar.gz -O physfs-3.2.0.tar.gz
tar -xf physfs-3.2.0.tar.gz
cmake -S physfs-release-3.2.0 -B build-physfs -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DPHYSFS_BUILD_SHARED=OFF -DPHYSFS_BUILD_STATIC=ON -DPHYSFS_BUILD_TEST=OFF
cmake --build build-physfs --parallel
cmake --install build-physfs
rm -r build-physfs physfs-release-3.2.0 physfs-3.2.0.tar.gz
echo "Test: pkg-config --cflags --libs physfs"

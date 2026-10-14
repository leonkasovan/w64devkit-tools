#!/bin/bash
set -e
#deps: none
#desc: Simple OpenGL Image Library (SOIL)
#version: 1.16
#name: soil

source "$(dirname "$0")/common.sh"
skip_if_installed "soil" "$INSTALL_PREFIX/lib/libSOIL.a" "SOIL"

wget https://github.com/kbranigan/Simple-OpenGL-Image-Library/archive/refs/heads/master.zip -O SOIL.zip
unzip -o SOIL.zip
SOIL_DIR="Simple-OpenGL-Image-Library-master"
cd "$SOIL_DIR/src"
gcc -c -O2 -I. -w SOIL.c image_DXT.c image_helper.c stb_image_aug.c
ar rcs libSOIL.a SOIL.o image_DXT.o image_helper.o stb_image_aug.o
mkdir -p "$INSTALL_PREFIX/include/SOIL" "$INSTALL_PREFIX/lib/pkgconfig"
cp SOIL.h image_DXT.h image_helper.h stb_image_aug.h stbi_DDS_aug.h stbi_DDS_aug_c.h "$INSTALL_PREFIX/include/SOIL/"
cp libSOIL.a "$INSTALL_PREFIX/lib/"
cat > "$INSTALL_PREFIX/lib/pkgconfig/soil.pc" <<EOF
prefix=$INSTALL_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${exec_prefix}/include

Name: soil
Description: Simple OpenGL Image Library
Version: 1.16
Libs: -L\${libdir} -lSOIL -lopengl32
Cflags: -I\${includedir}/SOIL
EOF
cd ../..
rm -rf "$SOIL_DIR" SOIL.zip
echo "Test: ls $INSTALL_PREFIX/lib/libSOIL.a $INSTALL_PREFIX/include/SOIL/SOIL.h"

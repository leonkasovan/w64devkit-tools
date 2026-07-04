#!/bin/bash
set -e
#deps: none
#desc: OpenGL Extension Wrangler library
#version: 2.2.0
#name: glew

source "$(dirname "$0")/common.sh"
skip_if_installed "glew" "$INSTALL_PREFIX/lib/libglew32s.a" "glew"

wget https://downloads.sourceforge.net/project/glew/glew/2.2.0/glew-2.2.0.zip -O glew-2.2.0.zip || \
wget http://downloads.sourceforge.net/project/glew/glew/2.2.0/glew-2.2.0.zip -O glew-2.2.0.zip
unzip -o glew-2.2.0.zip
GLEW_DIR=""
if [ -d "glew-2.2.0" ]; then GLEW_DIR="glew-2.2.0"; else GLEW_DIR="glew-glew-2.2.0"; fi
cd "$GLEW_DIR"
gcc -c -O2 -DGLEW_STATIC -Iinclude src/glew.c -o glew.o
ar rcs libglew32s.a glew.o
mkdir -p "$INSTALL_PREFIX/include/GL" "$INSTALL_PREFIX/lib/pkgconfig"
cp include/GL/glew.h "$INSTALL_PREFIX/include/GL/"
cp libglew32s.a "$INSTALL_PREFIX/lib/"
cat > "$INSTALL_PREFIX/lib/pkgconfig/glew.pc" <<EOF
prefix=$INSTALL_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${exec_prefix}/include

Name: glew
Description: OpenGL Extension Wrangler
Version: 2.2.0
Libs: -L\${libdir} -lglew32s -lglu32 -lopengl32
Cflags: -I\${includedir}
EOF
cd ..
rm -rf "$GLEW_DIR" glew-2.2.0.zip
echo "Test: ls $INSTALL_PREFIX/lib/libglew32s.a $INSTALL_PREFIX/include/GL/glew.h"

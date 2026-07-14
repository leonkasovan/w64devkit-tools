#!/bin/bash
set -e
#deps: glfw
#desc: Dear ImGui immediate mode GUI
#version: 1.92.8
#name: imgui

source "$(dirname "$0")/common.sh"
skip_if_installed "imgui" "$INSTALL_PREFIX/lib/libimgui.a" "imgui"

wget https://github.com/ocornut/imgui/archive/refs/tags/v1.92.8.zip -O imgui-1.92.8.zip
unzip -o imgui-1.92.8.zip || true

IMGUI_DIR="imgui-1.92.8"
# Install core + backend headers together in the imgui root. The backend
# headers do `#include "imgui.h"` (quote-include), so they must sit next to
# imgui.h for consumers to resolve it.
mkdir -p "$INSTALL_PREFIX/include/imgui"
cp "$IMGUI_DIR"/imgui.h "$IMGUI_DIR"/imconfig.h "$INSTALL_PREFIX/include/imgui/"
cp "$IMGUI_DIR"/backends/imgui_impl_glfw.h \
   "$IMGUI_DIR"/backends/imgui_impl_opengl3.h \
   "$IMGUI_DIR"/backends/imgui_impl_opengl3_loader.h \
   "$INSTALL_PREFIX/include/imgui/"
rm -rf "$INSTALL_PREFIX/include/imgui/backends"

# Compile core + GLFW/OpenGL3 backend into a single static library.
# glfw3.h is pulled from the installed prefix; the OpenGL3 backend ships its
# own GL loader so no extra GL dependency is required at compile time.
gcc -c -O2 -I"$IMGUI_DIR" -I"$IMGUI_DIR"/backends -I"$INSTALL_PREFIX/include" \
  "$IMGUI_DIR"/imgui.cpp \
  "$IMGUI_DIR"/imgui_draw.cpp \
  "$IMGUI_DIR"/imgui_widgets.cpp \
  "$IMGUI_DIR"/imgui_tables.cpp \
  "$IMGUI_DIR"/imgui_demo.cpp \
  "$IMGUI_DIR"/backends/imgui_impl_glfw.cpp \
  "$IMGUI_DIR"/backends/imgui_impl_opengl3.cpp
ar rcs "$INSTALL_PREFIX/lib/libimgui.a" *.o
rm -f *.o

# pkg-config file. Force the exact static lib; glfw3 is required privately.
# No -lopengl32: the OpenGL3 backend ships its own GL loader
# (imgui_impl_opengl3_loader.h) which resolves GL functions at runtime via
# wglGetProcAddress/GetProcAddress, so there is no link-time GL dependency.
mkdir -p "$INSTALL_PREFIX/lib/pkgconfig"
cat > "$INSTALL_PREFIX/lib/pkgconfig/imgui.pc" <<EOF
prefix=$INSTALL_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: imgui
Description: Dear ImGui immediate mode GUI
Version: 1.92.8
Requires.private: glfw3
Libs: -L\${libdir} -l:libimgui.a
Cflags: -I\${includedir}
EOF

rm -r "$IMGUI_DIR" imgui-1.92.8.zip
echo "Test: pkg-config --cflags --libs imgui"

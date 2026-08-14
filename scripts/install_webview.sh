#!/bin/bash
set -e
#deps: none
#desc: Tiny cross-platform webview UI (WebView2 backend)
#version: 0.12.0
#name: webview

source "$(dirname "$0")/common.sh"
skip_if_installed "webview" "$INSTALL_PREFIX/lib/libwebview.a" "webview"

wget https://github.com/webview/webview/archive/refs/heads/master.zip -O webview-master.zip
unzip -o webview-master.zip
cmake -S webview-master -B build-webview -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_BUILD_TYPE=Release -DWEBVIEW_BUILD_SHARED_LIBRARY=OFF -DWEBVIEW_BUILD_STATIC_LIBRARY=ON -DWEBVIEW_BUILD_TESTS=OFF -DWEBVIEW_BUILD_EXAMPLES=OFF -DWEBVIEW_BUILD_DOCS=OFF -DWEBVIEW_USE_COMPAT_MINGW=ON
cmake --build build-webview --parallel
cmake --install build-webview
rm -r build-webview webview-master webview-master.zip
echo "Test: ls $INSTALL_PREFIX/lib/libwebview.a $INSTALL_PREFIX/include/webview/webview.h"

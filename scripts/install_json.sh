#!/bin/bash
set -e
#deps: none
#desc: JSON for Modern C++ (header-only)
#version: 3.11.3
#name: json

INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && [ -f "$INSTALL_PREFIX/include/nlohmann/json.hpp" ]; then
    echo "[SKIPPED] json already installed"; exit 0
fi

wget https://github.com/nlohmann/json/archive/refs/tags/v3.11.3.tar.gz -O json-3.11.3.tar.gz
tar -xf json-3.11.3.tar.gz
cmake -S json-3.11.3 -B build-json -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DJSON_BuildTests=OFF -DJSON_CI=OFF
cmake --build build-json
cmake --install build-json
rm -r build-json json-3.11.3 json-3.11.3.tar.gz
echo "Test: ls $INSTALL_PREFIX/include/nlohmann/json.hpp"

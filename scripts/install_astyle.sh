#!/bin/bash
set -e
#deps: none
#desc: Artistic Style code formatter (astyle.exe)
#version: 3.6.18
#name: astyle

source "$(dirname "$0")/common.sh"
skip_if_installed "astyle" "$INSTALL_PREFIX/bin/astyle.exe" "astyle"

wget https://gitlab.com/saalen/astyle/-/archive/3.6.18/astyle-3.6.18.zip -O astyle-3.6.18.zip
# sanity check: the download should be a zip archive (starts with PK header)
if [ "$(od -An -N2 -tx1 astyle-3.6.18.zip | tr -d ' \n')" != "504b" ]; then
    echo "error: astyle-3.6.18.zip is not a zip archive (download failed?)"
    exit 1
fi
unzip -qo astyle-3.6.18.zip
(
  cd astyle-3.6.18/AStyle/build/gcc
  make -j"$(nproc)" CFLAGS="-O2 -DNDEBUG -Wno-unknown-pragmas" LDFLAGS="-s"
)
mkdir -p "$INSTALL_PREFIX/bin"
cp -f astyle-3.6.18/AStyle/build/gcc/bin/astyle.exe "$INSTALL_PREFIX/bin/astyle.exe"
rm -f astyle-3.6.18.zip || true
rm -rf astyle-3.6.18 || true
echo "Test: \"$INSTALL_PREFIX\"/bin/astyle.exe --version"

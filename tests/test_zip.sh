#!/bin/bash
set -e
#deps: zip
#desc: Test zip installation

PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"
ZIP="$PREFIX/bin/zip.exe"
UNZIP="$PREFIX/bin/unzip.exe"

"$ZIP" -h >/dev/null

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
echo "hello zip" > "$tmp/hello.txt"
echo "second file" > "$tmp/second.txt"

(
  cd "$tmp"
  "$ZIP" -q test.zip hello.txt second.txt
  test -s test.zip
  if [ -x "$UNZIP" ]; then
    "$UNZIP" -t test.zip >/dev/null
  fi
)
echo "zip OK: created and verified test.zip"

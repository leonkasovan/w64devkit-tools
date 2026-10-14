#!/bin/bash
set -e
#deps: none
#desc: Go programming language toolchain (go.exe, gofmt.exe)
#version: 1.26.6
#name: go

source "$(dirname "$0")/common.sh"
skip_if_installed "go" "$INSTALL_PREFIX/bin/go.exe" "go"

# Pick the official Go zip for the host architecture. The app runs scripts
# with w64devkit's busybox ash, where `uname -m` reports x86_64 / i686 /
# aarch64 etc.; map that to Go's amd64 / 386 / arm64 naming.
case "$(uname -m)" in
  x86_64|amd64) GOARCH=amd64 ;;
  aarch64|arm64) GOARCH=arm64 ;;
  i386|i486|i586|i686) GOARCH=386 ;;
  *)
    echo "error: unsupported architecture: $(uname -m)"
    exit 1
    ;;
esac

GO_VERSION=1.26.6
ZIP="go${GO_VERSION}.windows-${GOARCH}.zip"
wget "https://go.dev/dl/${ZIP}" -O "$ZIP"
# sanity check: go.dev can return an HTML error page instead of the file
if [ "$(od -An -N2 -tx1 "$ZIP" | tr -d ' \n')" != "504b" ]; then
    echo "error: $ZIP is not a zip archive (download failed?)"
    exit 1
fi
unzip -o "$ZIP"

# Merge the top-level go/ directory into the prefix: go.exe and gofmt.exe
# land in <prefix>/bin, and Go derives GOROOT as <prefix> from the executable
# location, so no GOROOT/PATH setup is needed beyond w64devkit's own bin dir.
mkdir -p "$INSTALL_PREFIX/bin"
cp -rf go/* "$INSTALL_PREFIX/"
rm -r go "$ZIP"
echo "Test: \"$INSTALL_PREFIX\"/bin/go.exe version"

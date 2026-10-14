#!/bin/bash
set -e
#deps: go
#desc: Test Go installation

PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"
GO="$PREFIX/bin/go.exe"

if [ ! -x "$GO" ]; then
    echo "FAIL: $GO not found"
    exit 1
fi

"$GO" version

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/hello.go" <<'EOF'
package main

import "fmt"

func main() {
	fmt.Println("hello go")
}
EOF
out=$("$GO" run "$tmp/hello.go")
if [ "$out" != "hello go" ]; then
    echo "FAIL: go run output was: $out"
    exit 1
fi
echo "go OK: $("$GO" version | head -n 1)"

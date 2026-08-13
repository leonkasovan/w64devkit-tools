#!/bin/bash
set -e
#deps: nasm
#desc: Test nasm installation

PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"
NASM="$PREFIX/bin/nasm.exe"

"$NASM" -v >/dev/null

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/hello.asm" <<'EOF'
BITS 64
global myfunc
section .text
myfunc:
    mov eax, 42
    ret
EOF

"$NASM" -f win64 "$tmp/hello.asm" -o "$tmp/hello.obj"
test -s "$tmp/hello.obj"
# win64 COFF objects start with the AMD64 machine id 0x8664
if [ "$(od -An -N2 -tx1 "$tmp/hello.obj" | tr -d ' \n')" != "6486" ]; then
    echo "error: hello.obj is not a valid AMD64 COFF object"
    exit 1
fi
echo "nasm OK: assembled hello.obj"

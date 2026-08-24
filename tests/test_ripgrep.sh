#!/bin/bash
set -e
#deps: ripgrep
#desc: Test ripgrep installation

PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"
RG="$PREFIX/bin/rg.exe"

# Test version output
"$RG" --version >/dev/null

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Create test files
cat > "$tmp/hello.txt" <<'EOF'
hello world
foo bar baz
hello again
EOF

cat > "$tmp/ignore.txt" <<'EOF'
should not be found
EOF

# Test basic search
count=$("$RG" -c "hello" "$tmp" 2>/dev/null | grep -c "hello.txt" || true)
if [ "$count" != "1" ]; then
    echo "error: rg did not find 'hello' in hello.txt"
    exit 1
fi

# Test regex
result=$("$RG" "foo|baz" "$tmp/hello.txt" 2>/dev/null | wc -l)
if [ "$result" != "1" ]; then
    echo "error: rg regex 'foo|baz' failed"
    exit 1
fi

echo "rg OK: $( "$RG" --version | head -1 )"

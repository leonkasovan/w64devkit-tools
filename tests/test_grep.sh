#!/bin/bash
set -e
#deps: grep
#desc: Test GNU grep installation

PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"
GREP="$PREFIX/bin/grep.exe"

# Test version output
"$GREP" --version >/dev/null

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Create test files
cat > "$tmp/hello.txt" <<'EOF'
hello world
foo bar baz
hello again
EOF

# Test basic search
count=$("$GREP" -c "hello" "$tmp/hello.txt")
if [ "$count" != "2" ]; then
    echo "error: grep -c 'hello' expected 2, got $count"
    exit 1
fi

# Test regex
result=$("$GREP" -E "foo|baz" "$tmp/hello.txt" | wc -l)
if [ "$result" != "1" ]; then
    echo "error: grep -E 'foo|baz' failed"
    exit 1
fi

# Test -r (recursive)
mkdir -p "$tmp/sub"
cp "$tmp/hello.txt" "$tmp/sub/nested.txt"
count=$("$GREP" -r -c "hello" "$tmp/sub" | wc -l)
if [ "$count" != "1" ]; then
    echo "error: grep -r failed"
    exit 1
fi

echo "grep OK: $( "$GREP" --version | head -1 )"

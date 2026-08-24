#!/bin/bash
set -e
#deps: xmllint
#desc: Test xmllint installation

PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"
XMLLINT="$PREFIX/bin/xmllint.exe"

# Test version output
"$XMLLINT" --version >/dev/null 2>&1

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Test XML formatting
cat > "$tmp/ugly.xml" <<'EOF'
<root><item name="a"><value>1</value></item><item name="b"><value>2</value></item></root>
EOF

"$XMLLINT" --format "$tmp/ugly.xml" > "$tmp/formatted.xml"
# Check that formatting added indentation
if ! grep -q '  <item' "$tmp/formatted.xml"; then
    echo "error: xmllint --format did not indent XML"
    exit 1
fi

# Test HTML formatting
cat > "$tmp/ugly.html" <<'EOF'
<html><head><title>Test</title></head><body><p>Hello</p></body></html>
EOF

"$XMLLINT" --html --format "$tmp/ugly.html" > "$tmp/formatted.html" 2>/dev/null
if ! grep -q '<p>' "$tmp/formatted.html"; then
    echo "error: xmllint --html --format failed"
    exit 1
fi

echo "xmllint OK: formatted XML and HTML"

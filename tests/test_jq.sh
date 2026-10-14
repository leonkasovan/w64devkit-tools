#!/bin/bash
set -e
#deps: jq
#desc: Test jq installation

PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"
JQ="$PREFIX/bin/jq.exe"

# Test version output
"$JQ" --version >/dev/null

# Test formatting: pretty-print compact JSON
result=$(echo '{"name":"test","value":42}' | "$JQ" '.')
if [ "$result" != $'{\n  "name": "test",\n  "value": 42\n}' ]; then
    echo "error: jq did not format JSON correctly"
    echo "got: $result"
    exit 1
fi

# Test query
result=$(echo '{"name":"test","value":42}' | "$JQ" -r '.name')
if [ "$result" != "test" ]; then
    echo "error: jq query failed"
    echo "got: $result"
    exit 1
fi

echo "jq OK: $( "$JQ" --version )"

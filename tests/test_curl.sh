#!/bin/bash
set -e
#deps: curl
#desc: Test libcurl and curl.exe installation

PREFIX="${INSTALL_PREFIX:-${1:-C:/w64devkit}}"

# Compile the test program
gcc test_curl.c -o test_curl $(pkg-config --cflags libcurl) $(pkg-config --static --libs libcurl) -mconsole

# Run the test program
./test_curl

# Verify the curl.exe tool is installed and reports the expected version
curl_exe="$PREFIX/bin/curl.exe"
[ -x "$curl_exe" ] || { echo "FAIL: $curl_exe not found"; exit 1; }
"$curl_exe" --version | grep -q "8.19.0"
echo "curl.exe OK: $("$curl_exe" --version | head -n 1)"
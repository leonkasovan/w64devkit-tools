#!/bin/bash
set -e
#deps: curl
#desc: Test libcurl installation

# Compile the test program
gcc test_curl.c -o test_curl $(pkg-config --cflags libcurl) $(pkg-config --static --libs libcurl) -mconsole

# Run the test program
./test_curl
#!/bin/bash
set -e
#deps: zstd
#desc: Test Zstandard installation

# Compile the test program
gcc test_zstd.c -o test_zstd $(pkg-config --cflags libzstd) $(pkg-config --static --libs libzstd) -mconsole

# Run the test program
./test_zstd

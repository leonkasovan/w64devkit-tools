#!/bin/bash
set -e
#deps: brotli
#desc: Test brotli installation

# Compile the test program
gcc test_brotli.c -o test_brotli $(pkg-config --cflags libbrotlidec libbrotlicommon) $(pkg-config --static --libs libbrotlidec libbrotlicommon) -mconsole

# Run the test program
./test_brotli

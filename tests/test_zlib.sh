#!/bin/bash
set -e
#deps: zlib
#desc: Test zlib installation

# Compile the test program
gcc test_zlib.c -o test_zlib $(pkg-config --cflags zlib) $(pkg-config --static --libs zlib) -mconsole

# Run the test program
./test_zlib

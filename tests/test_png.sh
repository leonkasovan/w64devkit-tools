#!/bin/bash
set -e
#deps: png
#desc: Test libpng installation

# Compile the test program
gcc test_png.c -o test_png $(pkg-config --cflags libpng) $(pkg-config --static --libs libpng) -mconsole

# Run the test program
./test_png

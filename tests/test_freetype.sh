#!/bin/bash
set -e
#deps: freetype
#desc: Test FreeType installation

# Compile the test program
gcc test_freetype.c -o test_freetype $(pkg-config --cflags freetype2) $(pkg-config --static --libs freetype2) -mconsole

# Run the test program
./test_freetype

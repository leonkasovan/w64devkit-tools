#!/bin/bash
set -e
#deps: lzma
#desc: Test liblzma installation

# Compile the test program
gcc test_lzma.c -o test_lzma $(pkg-config --cflags liblzma) $(pkg-config --static --libs liblzma) -mconsole

# Run the test program
./test_lzma

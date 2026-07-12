#!/bin/bash
set -e
#deps: ogg
#desc: Test libogg installation

# Compile the test program
gcc test_ogg.c -o test_ogg $(pkg-config --cflags ogg) $(pkg-config --static --libs ogg) -mconsole

# Run the test program
./test_ogg

#!/bin/bash
set -e
#deps: minizip
#desc: Test minizip installation

# Compile the test program
gcc test_minizip.c -o test_minizip $(pkg-config --cflags minizip) $(pkg-config --static --libs minizip) -mconsole

# Run the test program
./test_minizip
#!/bin/bash
set -e
#deps: opus
#desc: Test Opus codec installation

# Compile the test program
gcc test_opus.c -o test_opus $(pkg-config --cflags opus) $(pkg-config --static --libs opus) -mconsole

# Run the test program
./test_opus

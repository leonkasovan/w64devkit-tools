#!/bin/bash
set -e
#deps: opusfile
#desc: Test Opusfile installation

# Compile the test program
gcc test_opusfile.c -o test_opusfile $(pkg-config --cflags opusfile) $(pkg-config --static --libs opusfile) -mconsole

# Run the test program
./test_opusfile

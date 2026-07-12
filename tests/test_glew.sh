#!/bin/bash
set -e
#deps: glew
#desc: Test GLEW installation

# Compile the test program
gcc test_glew.c -o test_glew $(pkg-config --cflags glew) $(pkg-config --static --libs glew) -mconsole

# Run the test program
./test_glew

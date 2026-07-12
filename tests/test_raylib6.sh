#!/bin/bash
set -e
#deps: raylib6
#desc: Test raylib installation

# Compile the test program
gcc test_raylib6.c -o test_raylib6 $(pkg-config --cflags raylib) $(pkg-config --static --libs raylib) -mconsole

# Run the test program
./test_raylib6

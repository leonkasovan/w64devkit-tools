#!/bin/bash
set -e
#deps: glfw
#desc: Test GLFW installation

# Compile the test program
gcc test_glfw.c -o test_glfw $(pkg-config --cflags glfw3) $(pkg-config --static --libs glfw3) -mconsole

# Run the test program
./test_glfw

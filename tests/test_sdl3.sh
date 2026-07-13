#!/bin/bash
set -e
#deps: sdl3
#desc: Test SDL3 installation

# Compile the test program
gcc test_sdl3.c -o test_sdl3 $(pkg-config --cflags sdl3) -Umain -DSDL_MAIN_HANDLED $(pkg-config --static --libs sdl3) -mconsole

# Run the test program
./test_sdl3

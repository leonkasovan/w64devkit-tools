#!/bin/bash
set -e
#deps: sdl2
#desc: Test SDL2 installation

# Compile the test program
gcc test_sdl2.c -o test_sdl2 $(pkg-config --cflags sdl2) -Umain -DSDL_MAIN_HANDLED $(pkg-config --static --libs sdl2 | sed -e 's/-lSDL2main//' -e 's/-lSDL2/-l:libSDL2.a/') -mconsole

# Run the test program
./test_sdl2

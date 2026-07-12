#!/bin/bash
set -e
#deps: sdl2ttf
#desc: Test SDL2_ttf installation

# Compile the test program
gcc test_sdl2ttf.c -o test_sdl2ttf $(pkg-config --cflags sdl2 SDL2_ttf) -Umain -DSDL_MAIN_HANDLED $(pkg-config --static --libs sdl2 SDL2_ttf | sed -e 's/-lSDL2main//' -e 's/-lSDL2\b/-l:libSDL2.a/') -mconsole

# Run the test program
./test_sdl2ttf

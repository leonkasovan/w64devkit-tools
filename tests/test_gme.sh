#!/bin/bash
set -e
#deps: gme
#desc: Test game-music-emu installation

# Compile the test program
gcc test_gme.c -o test_gme $(pkg-config --cflags libgme) $(pkg-config --static --libs libgme) -mconsole

# Run the test program
./test_gme

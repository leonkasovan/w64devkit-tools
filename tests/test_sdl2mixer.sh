#!/bin/bash
set -e
#deps: sdl2mixer
#desc: Test SDL2 mixer installation

# Compile the test program and use console subsystem to avoid creating a new console window on Windows
gcc test_sdl2mixer.c -o test_sdl2mixer $(pkg-config --cflags sdl2 SDL2_mixer) $(pkg-config --static --libs sdl2 SDL2_mixer) -mconsole

# Download a sample OGG file for testing
wget https://sample-files.com/downloads/audio/ogg/music-sample-128kbps.ogg -O sample.ogg

# Run the test program with the downloaded sample OGG file
./test_sdl2mixer sample.ogg

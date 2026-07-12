#!/bin/bash
set -e
#deps: sdl2image
#desc: Test SDL2 image installation

# Compile the test program
gcc test_sdl2image.c -o test_sdl2image $(pkg-config --cflags sdl2 SDL2_image) $(pkg-config --static --libs sdl2 SDL2_image | sed -e 's/-lSDL2\b/-l:libSDL2.a/') -mconsole

# Download a sample JPG file for testing if sample.jpg does not exist
if [ ! -f sample.jpg ]; then
    wget https://images-assets.nasa.gov/image/GSFC_20171208_Archive_e000496/GSFC_20171208_Archive_e000496~thumb.jpg -O sample.jpg
fi

# Run the test program with the sample JPG file
./test_sdl2image sample.jpg

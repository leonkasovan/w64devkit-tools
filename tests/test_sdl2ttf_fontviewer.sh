#!/bin/bash
set -e
#deps: sdl2ttf
#desc: Test SDL2_ttf font viewer installation

# Compile the test program
gcc test_sdl2ttf_fontviewer.c -o test_sdl2ttf_fontviewer $(pkg-config --cflags sdl2 SDL2_ttf) $(pkg-config --static --libs sdl2 SDL2_ttf) -mconsole

# Download a sample TTF font for testing (DejaVu Sans)
if [ ! -f DejaVuSans.ttf ]; then
    wget https://github.com/google/fonts/raw/refs/heads/main/ofl/abeezee/ABeeZee-Regular.ttf -O sample.ttf
fi

# Run the test program with the sample font
# Display "The quick brown fox..." for 5 seconds or until ESC pressed
./test_sdl2ttf_fontviewer sample.ttf "The quick brown fox jumps over the lazy dog" 24
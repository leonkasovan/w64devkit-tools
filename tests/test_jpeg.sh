#!/bin/bash
set -e
#deps: jpeg
#desc: Test libjpeg installation

# Compile the test program
gcc test_jpeg.c -o test_jpeg $(pkg-config --cflags libjpeg) $(pkg-config --static --libs libjpeg) -mconsole

# Run the test program
./test_jpeg

#!/bin/bash
set -e
#deps: webp
#desc: Test WebP installation

# Compile the test program
gcc test_webp.c -o test_webp $(pkg-config --cflags libwebp) $(pkg-config --static --libs libwebp) -mconsole

# Run the test program
./test_webp

#!/bin/bash
set -e
#deps: harfbuzz
#desc: Test HarfBuzz installation

# Compile the test program
gcc test_harfbuzz.c -o test_harfbuzz $(pkg-config --cflags harfbuzz) $(pkg-config --static --libs harfbuzz) -mconsole

# Run the test program
./test_harfbuzz

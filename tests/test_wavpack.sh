#!/bin/bash
set -e
#deps: wavpack
#desc: Test WavPack installation

# Compile the test program
gcc test_wavpack.c -o test_wavpack $(pkg-config --cflags wavpack) $(pkg-config --static --libs wavpack) -mconsole

# Run the test program
./test_wavpack

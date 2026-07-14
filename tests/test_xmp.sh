#!/bin/bash
set -e
#deps: xmp
#desc: Test libxmp installation

# Compile the test program
gcc test_xmp.c -o test_xmp -DLIBXMP_STATIC $(pkg-config --cflags libxmp) $(pkg-config --static --libs libxmp) -mconsole

# Run the test program
./test_xmp

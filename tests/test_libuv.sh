#!/bin/bash
set -e
#deps: libuv
#desc: Test libuv installation

# Compile the test program
gcc test_libuv.c -o test_libuv $(pkg-config --cflags libuv) $(pkg-config --static --libs libuv) -mconsole

# Run the test program
./test_libuv
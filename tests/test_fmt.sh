#!/bin/bash
set -e
#deps: fmt
#desc: Test fmt installation

# Compile the test program
g++ test_fmt.cpp -o test_fmt $(pkg-config --cflags fmt) $(pkg-config --static --libs fmt) -mconsole

# Run the test program
./test_fmt
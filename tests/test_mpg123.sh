#!/bin/bash
set -e
#deps: mpg123
#desc: Test mpg123 installation

# Compile the test program
gcc test_mpg123.c -o test_mpg123 $(pkg-config --cflags libmpg123) $(pkg-config --static --libs libmpg123) -mconsole

# Run the test program
./test_mpg123

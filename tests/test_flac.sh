#!/bin/bash
set -e
#deps: flac
#desc: Test FLAC installation

# Compile the test program
gcc test_flac.c -o test_flac $(pkg-config --cflags flac) -DFLAC__NO_DLL $(pkg-config --static --libs flac) -mconsole

# Run the test program
./test_flac

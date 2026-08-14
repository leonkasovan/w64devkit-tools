#!/bin/bash
set -e
#deps: cjson
#desc: Test cJSON installation

# Compile the test program
gcc test_cjson.c -o test_cjson $(pkg-config --cflags libcjson) $(pkg-config --static --libs libcjson) -mconsole

# Run the test program
./test_cjson

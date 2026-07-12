#!/bin/bash
set -e
#deps: pcre2
#desc: Test PCRE2 installation

# Compile the test program
gcc test_pcre2.c -o test_pcre2 $(pkg-config --cflags libpcre2-8) -DPCRE2_STATIC $(pkg-config --static --libs libpcre2-8) -mconsole

# Run the test program
./test_pcre2
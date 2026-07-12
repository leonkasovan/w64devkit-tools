#!/bin/bash
set -e
#deps: xml
#desc: Test expat XML parser installation

# Compile the test program
gcc test_xml.c -o test_xml $(pkg-config --cflags expat) $(pkg-config --static --libs expat) -mconsole

# Run the test program
./test_xml
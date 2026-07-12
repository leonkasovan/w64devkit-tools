#!/bin/bash
set -e
#deps: bz2
#desc: Test bzip2 installation

# No pkg-config file for bz2, so use INSTALL_PREFIX with a fallback default
PREFIX="${INSTALL_PREFIX:-C:/w64devkit}"

# Compile the test program
gcc test_bz2.c -o test_bz2 -I"$PREFIX/include" -L"$PREFIX/lib" -lbz2 -mconsole

# Run the test program
./test_bz2

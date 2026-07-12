#!/bin/bash
set -e
#deps: sqlite3
#desc: Test SQLite3 installation

# Compile the test program
gcc test_sqlite3.c -o test_sqlite3 $(pkg-config --cflags sqlite3) $(pkg-config --static --libs sqlite3) -mconsole

# Run the test program
./test_sqlite3
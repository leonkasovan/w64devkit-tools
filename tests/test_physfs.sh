#!/bin/bash
set -e
#deps: physfs
#desc: Test PhysicsFS installation

# Compile the test program
gcc test_physfs.c -o test_physfs $(pkg-config --cflags physfs) -DPHYSFS_STATIC $(pkg-config --static --libs physfs) -mconsole

# Run the test program
./test_physfs

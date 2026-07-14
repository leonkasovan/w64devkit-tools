#!/bin/bash
set -e
#deps: imgui
#desc: Test imgui installation

# Compile the test program (imgui is C++, use g++)
g++ test_imgui.cpp -o test_imgui $(pkg-config --cflags imgui) $(pkg-config --static --libs imgui) -mconsole

# Run the test program
./test_imgui

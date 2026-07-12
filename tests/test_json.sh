#!/bin/bash
set -e
#deps: json
#desc: Test nlohmann/json installation

# Compile the test program
g++ test_json.cpp -o test_json $(pkg-config --cflags nlohmann_json) $(pkg-config --static --libs nlohmann_json) -mconsole

# Run the test program
./test_json
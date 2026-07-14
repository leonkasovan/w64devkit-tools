#!/bin/bash
set -e
#deps: ffmpeg
#desc: Test FFmpeg installation

# Compile the test program
gcc test_ffmpeg.c -o test_ffmpeg $(pkg-config --cflags libavutil) $(pkg-config --static --libs libavutil) -mconsole

# Run the test program
./test_ffmpeg

#!/bin/bash
set -e
#deps: sdl2, ogg, opus, opusfile, xmp, wavpack, mpg123, flac, gme
#desc: SDL2 audio mixer
#version: 2.8.2
#name: sdl2mixer

# Use first argument if provided, otherwise use default
INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists SDL2_mixer 2>/dev/null || [ -f "$INSTALL_PREFIX/lib/libSDL2_mixer.a" ] ); then
    echo "[SKIPPED] sdl2mixer already installed"; exit 0
fi

wget https://github.com/libsdl-org/SDL_mixer/archive/refs/tags/release-2.8.2.zip -O sdl2_mixer-2.8.2.zip
unzip -o sdl2_mixer-2.8.2.zip
cmake -S SDL_mixer-release-2.8.2 -B build_sdl2mixer -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX" -DBUILD_SHARED_LIBS=OFF -DSDL2MIXER_SAMPLES=OFF -DSDL2MIXER_MIDI=ON -DSDL2MIXER_MIDI_NATIVE=ON -DSDL2MIXER_MIDI_FLUIDSYNTH=OFF -DSDL2MIXER_MIDI_TIMIDITY=OFF -DSDL2MIXER_OPUS_SHARED=OFF -DSDL2MIXER_MOD_XMP=ON -DSDL2MIXER_MOD_XMP_SHARED=OFF -DSDL2MIXER_WAVPACK_SHARED=OFF -DSDL2MIXER_MP3_MPG123=ON -DSDL2MIXER_MP3_MPG123_SHARED=OFF -DSDL2MIXER_FLAC=ON -DSDL2MIXER_FLAC_LIBFLAC=ON -DSDL2MIXER_FLAC_LIBFLAC_SHARED=OFF -DSDL2MIXER_GME=ON -DSDL2MIXER_GME_SHARED=OFF -DOpusFile_LIBRARY="$INSTALL_PREFIX/lib/libopusfile.a" -DOpusFile_INCLUDE_PATH="$INSTALL_PREFIX/include" -Dmpg123_LIBRARY="$INSTALL_PREFIX/lib/libmpg123.a" -Dmpg123_INCLUDE_PATH="$INSTALL_PREFIX/include"
cmake --build build_sdl2mixer --parallel
cmake --install build_sdl2mixer
rm -r build_sdl2mixer SDL_mixer-release-2.8.2 sdl2_mixer-2.8.2.zip
echo "Test: pkg-config --cflags --libs SDL2_mixer"

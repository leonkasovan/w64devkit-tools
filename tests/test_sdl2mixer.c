// test_sdl2mixer.c - minimal SDL2_mixer smoke test
// desc: SDL2_mixer audio playback test (plays OGG/MP3/FLAC/MOD files)
// deps: sdl2 SDL2_mixer
// #define SDL_MAIN_HANDLED
// Usage: test_sdl2mixer <soundfile>
// Loads and plays <soundfile>, and reports which decoder backends are
// linked into this build. To exercise every format, run once per format
// with a representative file (e.g. .ogg, .mp3, .flac, .mod, .opus, .wav).
// Build with: gcc test_sdl2mixer.c -o test_sdl2mixer $(pkg-config --cflags SDL2_mixer) $(pkg-config --static --libs SDL2_mixer) -mconsole
#include <SDL2/SDL.h>
#include <SDL2/SDL_mixer.h>
#include <stdio.h>

// ponytail: map Mix_MusicType enum to string for display.
static const char *music_type_name(int t) {
    switch (t) {
    case MUS_NONE:    return "NONE";
    case MUS_CMD:     return "CMD";
    case MUS_WAV:     return "WAV";
    case MUS_MOD:     return "MOD";
    case MUS_MID:     return "MIDI";
    case MUS_OGG:     return "OGG";
    case MUS_MP3:     return "MP3";
    case MUS_FLAC:    return "FLAC";
    case MUS_OPUS:    return "OPUS";
    case MUS_WAVPACK: return "WAVPACK";
    case MUS_GME:     return "GME";
    default:          return "?";
    }
}

int main(int argc, char **argv) {
    if (SDL_Init(SDL_INIT_AUDIO) < 0) {
        fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    // ponytail: request every backend; report which actually initialized.
    // A missing flag means that decoder wasn't linked into this build.
    int want = MIX_INIT_FLAC | MIX_INIT_MOD | MIX_INIT_MP3 | MIX_INIT_OGG;
    int got = Mix_Init(want);
    // printf("Backends requested=0x%x initialized=0x%x\n", want, got);

    if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) < 0) {
        fprintf(stderr, "Mix_OpenAudio failed: %s\n", Mix_GetError());
        return 1;
    }

    // ponytail: decoders are only registered after Mix_OpenAudio() opens
    // the audio device (open_music_type() populates the lists). Querying
    // them before OpenAudio returns 0 even though the backends linked in.
    int decoders = Mix_GetNumChunkDecoders();
    printf("\nChunk decoders supported=%d\n", decoders);
    for (int i = 0; i < decoders; i++) {
        const char *name = Mix_GetChunkDecoder(i);
        printf("  %s\n", name);
    }

    int music_decoders = Mix_GetNumMusicDecoders();
    printf("\nMusic decoders supported=%d\n", music_decoders);
    for (int i = 0; i < music_decoders; i++) {
        const char *name = Mix_GetMusicDecoder(i);
        printf("  %s\n", name);
    }

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <soundfile>\n", argv[0]);
        return 1;
    }

    Mix_Music *mus = Mix_LoadMUS(argv[1]);
    if (!mus) {
        fprintf(stderr, "Mix_LoadMUS failed: %s\n", Mix_GetError());
        return 1;
    }
    // ponytail: Mix_GetMusicType returns a Mix_MusicType enum, NOT a decoder
    // list index — passing it to Mix_GetMusicDecoder gives a wrong name.
    Mix_MusicType mtype = Mix_GetMusicType(mus);
    printf("\nLoaded '%s' (music type %s)\n", argv[1], music_type_name(mtype));

    // ponytail: loop once so short files still play audibly.
    if (Mix_PlayMusic(mus, 1) < 0) {
        fprintf(stderr, "Mix_PlayMusic failed: %s\n", Mix_GetError());
        return 1;
    }
    printf("playing... (Ctrl-C to stop)\n");
    while (Mix_PlayingMusic())
        SDL_Delay(100);

    Mix_FreeMusic(mus);
    Mix_CloseAudio();
    Mix_Quit();
    SDL_Quit();
    printf("OK\n");
    return 0;
}

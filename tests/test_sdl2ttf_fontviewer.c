// test_sdl2ttf_fontviewer.c - simple SDL2_ttf font viewer test
// desc: SDL2_ttf font rendering test (renders sample text with given font)
// deps: sdl2 sdl2ttf freetype harfbuzz
// Usage: test_sdl2ttf_fontviewer <fontfile> [text] [size]
// Build with: gcc test_sdl2ttf_fontviewer.c -o test_sdl2ttf_fontviewer $(pkg-config --cflags SDL2 SDL2_ttf) $(pkg-config --static --libs SDL2 SDL2_ttf) -mconsole
#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <fontfile> [text] [size]\n", argv[0]);
        fprintf(stderr, "  fontfile: path to TTF/OTF font file\n");
        fprintf(stderr, "  text:     text to render (default: \"The quick brown fox jumps over the lazy dog\")\n");
        fprintf(stderr, "  size:     font size in points (default: 24)\n");
        return 1;
    }

    const char *fontfile = argv[1];
    const char *text = (argc >= 3) ? argv[2] : "The quick brown fox jumps over the lazy dog";
    int ptsize = (argc >= 4) ? atoi(argv[3]) : 24;

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    if (TTF_Init() != 0) {
        fprintf(stderr, "TTF_Init failed: %s\n", TTF_GetError());
        SDL_Quit();
        return 1;
    }

    TTF_Font *font = TTF_OpenFont(fontfile, ptsize);
    if (!font) {
        fprintf(stderr, "TTF_OpenFont failed: %s\n", TTF_GetError());
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    // Get font info
    int style = TTF_GetFontStyle(font);
    int outline = TTF_GetFontOutline(font);
    int hinting = TTF_GetFontHinting(font);
    int kerning = TTF_GetFontKerning(font);
    int height = TTF_FontHeight(font);
    int ascent = TTF_FontAscent(font);
    int descent = TTF_FontDescent(font);
    int lineskip = TTF_FontLineSkip(font);
    int faces = TTF_FontFaces(font);
    int fixed = TTF_FontFaceIsFixedWidth(font);
    const char *familyname = TTF_FontFaceFamilyName(font);
    const char *stylename = TTF_FontFaceStyleName(font);

    printf("Font: %s\n", fontfile);
    printf("  Family: %s\n", familyname ? familyname : "(unknown)");
    printf("  Style:  %s\n", stylename ? stylename : "(unknown)");
    printf("  Size:   %d pt\n", ptsize);
    printf("  Height: %d, Ascent: %d, Descent: %d, LineSkip: %d\n", height, ascent, descent, lineskip);
    printf("  Faces:  %d, Fixed-width: %s\n", faces, fixed ? "yes" : "no");
    printf("  Style:  0x%x, Outline: %d, Hinting: %d, Kerning: %d\n", style, outline, hinting, kerning);

    // Render text to surface (blended mode for quality)
    SDL_Color fg = {255, 255, 255, 255};  // white
    SDL_Color bg = {0, 0, 0, 0};          // transparent background
    SDL_Surface *text_surface = TTF_RenderUTF8_Blended(font, text, fg);
    if (!text_surface) {
        fprintf(stderr, "TTF_RenderUTF8_Blended failed: %s\n", TTF_GetError());
        TTF_CloseFont(font);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    // Create window sized to text with some padding
    int padding = 20;
    int win_w = text_surface->w + padding * 2;
    int win_h = text_surface->h + padding * 2;

    SDL_Window *window = SDL_CreateWindow(
        "SDL2_ttf Font Viewer",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        win_w, win_h,
        0);

    if (!window) {
        fprintf(stderr, "SDL_CreateWindow failed: %s\n", SDL_GetError());
        SDL_FreeSurface(text_surface);
        TTF_CloseFont(font);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        fprintf(stderr, "SDL_CreateRenderer failed: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_FreeSurface(text_surface);
        TTF_CloseFont(font);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, text_surface);
    SDL_FreeSurface(text_surface);
    if (!texture) {
        fprintf(stderr, "SDL_CreateTextureFromSurface failed: %s\n", SDL_GetError());
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        TTF_CloseFont(font);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    // Render loop - display for 5 seconds or until quit/ESC
    Uint32 start = SDL_GetTicks();
    int running = 1;

    while (running) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT)
                running = 0;
            if (e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_ESCAPE)
                running = 0;
        }

        if (SDL_GetTicks() - start >= 5000)
            running = 0;

        SDL_SetRenderDrawColor(renderer, 30, 30, 40, 255);  // dark blue-gray background
        SDL_RenderClear(renderer);

        SDL_Rect dst = {padding, padding, 0, 0};
        SDL_QueryTexture(texture, NULL, NULL, &dst.w, &dst.h);
        SDL_RenderCopy(renderer, texture, NULL, &dst);

        SDL_RenderPresent(renderer);
        SDL_Delay(10);
    }

    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    TTF_CloseFont(font);
    TTF_Quit();
    SDL_Quit();

    printf("OK\n");
    return 0;
}
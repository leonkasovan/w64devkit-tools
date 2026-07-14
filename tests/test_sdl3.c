#include <SDL3/SDL.h>
#include <stdio.h>

int main(void) {
    int v = SDL_GetVersion();
    printf("sdl3 %d.%d.%d\n", SDL_VERSIONNUM_MAJOR(v), SDL_VERSIONNUM_MINOR(v), v % 1000);
    return 0;
}

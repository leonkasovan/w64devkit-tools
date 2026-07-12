#include <SDL3/SDL.h>
#include <stdio.h>

int main(void) {
    int major, minor, patch;
    SDL_GetVersion(&major, &minor, &patch);
    printf("sdl3 %d.%d.%d\n", major, minor, patch);
    return 0;
}

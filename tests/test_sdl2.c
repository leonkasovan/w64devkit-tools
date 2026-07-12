#include <SDL.h>
#include <stdio.h>

int main(void) {
    SDL_version v;
    SDL_GetVersion(&v);
    printf("sdl2 %d.%d.%d\n", v.major, v.minor, v.patch);

    int nvideo = SDL_GetNumVideoDrivers();
    printf("video drivers (%d):", nvideo);
    for (int i = 0; i < nvideo; i++)
        printf(" %s", SDL_GetVideoDriver(i));
    printf("\n");

    int naudio = SDL_GetNumAudioDrivers();
    printf("audio drivers (%d):", naudio);
    for (int i = 0; i < naudio; i++)
        printf(" %s", SDL_GetAudioDriver(i));
    printf("\n");

    return 0;
}

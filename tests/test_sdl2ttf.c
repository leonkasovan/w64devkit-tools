#include <SDL_ttf.h>
#include <stdio.h>

int main(void) {
    const SDL_version *v = TTF_Linked_Version();
    printf("sdl2ttf %d.%d.%d\n", v->major, v->minor, v->patch);
    return 0;
}

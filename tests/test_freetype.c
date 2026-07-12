#include <ft2build.h>
#include FT_FREETYPE_H
#include <stdio.h>

int main(void) {
    FT_Library lib;
    FT_Init_FreeType(&lib);
    printf("freetype %d.%d.%d\n", FREETYPE_MAJOR, FREETYPE_MINOR, FREETYPE_PATCH);
    return 0;
}

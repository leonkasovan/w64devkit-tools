#include <png.h>
#include <stdio.h>

int main(void) {
    printf("png %s\n", png_get_libpng_ver(NULL));
    return 0;
}

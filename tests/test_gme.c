#include <gme/gme.h>
#include <stdio.h>

int main(void) {
    printf("gme %d.%d.%d\n",
           (GME_VERSION >> 16) & 0xFF,
           (GME_VERSION >> 8) & 0xFF,
           GME_VERSION & 0xFF);
    (void)gme_track_count; /* force link against libgme */
    return 0;
}

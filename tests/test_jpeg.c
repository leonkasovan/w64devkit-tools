#include <stdio.h>
#include <stddef.h>
#include <jpeglib.h>

int main(void) {
    printf("jpeg %d\n", JPEG_LIB_VERSION);
    (void)jpeg_std_error; /* force link against libjpeg */
    return 0;
}

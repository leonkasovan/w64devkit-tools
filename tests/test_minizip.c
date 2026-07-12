#include <minizip/mz.h>
#include <minizip/mz_zip.h>
#include <stdio.h>

int main(void) {
    printf("minizip %s\n", MZ_VERSION);
    (void)mz_zip_close; /* force link against libminizip */
    return 0;
}

#include <zstd.h>
#include <stdio.h>

int main(void) {
    printf("zstd %s\n", ZSTD_versionString());
    return 0;
}

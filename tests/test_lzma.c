#include <lzma.h>
#include <stdio.h>

int main(void) {
    printf("lzma %s\n", lzma_version_string());
    return 0;
}

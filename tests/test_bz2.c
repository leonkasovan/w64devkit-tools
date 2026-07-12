#include <bzlib.h>
#include <stdio.h>

int main(void) {
    printf("bz2 %s\n", BZ2_bzlibVersion());
    return 0;
}

#include <wavpack/wavpack.h>
#include <stdio.h>

int main(void) {
    printf("wavpack %s\n", WavpackGetLibraryVersionString());
    return 0;
}

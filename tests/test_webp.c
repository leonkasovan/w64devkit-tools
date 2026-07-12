#include <webp/decode.h>
#include <stdio.h>

int main(void) {
    printf("webp %d\n", WebPGetDecoderVersion());
    return 0;
}

#include <brotli/decode.h>
#include <stdio.h>

int main(void) {
    uint32_t v = BrotliDecoderVersion();
    printf("brotli %u.%u.%u\n", v >> 24, (v >> 12) & 0xFFF, v & 0xFFF);
    return 0;
}

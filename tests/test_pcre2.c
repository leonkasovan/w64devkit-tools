#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
#include <stdio.h>

int main(void) {
    char ver[256];
    pcre2_config(PCRE2_CONFIG_VERSION, ver);
    printf("pcre2 %s\n", ver);
    return 0;
}

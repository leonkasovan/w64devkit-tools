#include <hb.h>
#include <stdio.h>

int main(void) {
    printf("harfbuzz %s\n", hb_version_string());
    return 0;
}

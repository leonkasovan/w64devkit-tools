#include <opus/opus.h>
#include <stdio.h>

int main(void) {
    printf("opus %s\n", opus_get_version_string());
    return 0;
}

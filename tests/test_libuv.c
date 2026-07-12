#include <uv.h>
#include <stdio.h>

int main(void) {
    printf("libuv %s\n", uv_version_string());
    return 0;
}

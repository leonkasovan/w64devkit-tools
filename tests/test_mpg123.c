#include <mpg123.h>
#include <stdio.h>

int main(void) {
    mpg123_init();
    printf("mpg123 %s\n", mpg123_distversion(NULL, NULL, NULL));
    return 0;
}

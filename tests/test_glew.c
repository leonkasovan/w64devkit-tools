#define GLEW_STATIC
#include <GL/glew.h>
#include <stdio.h>

int main(void) {
    printf("glew %s\n", glewGetString(GLEW_VERSION));
    return 0;
}

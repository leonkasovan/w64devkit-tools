#include <GLFW/glfw3.h>
#include <stdio.h>

int main(void) {
    int major, minor, revision;
    glfwGetVersion(&major, &minor, &revision);
    printf("glfw %d.%d.%d\n", major, minor, revision);
    return 0;
}

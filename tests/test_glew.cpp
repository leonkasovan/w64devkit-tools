#define GLEW_STATIC
#include <GL/glew.h>
int main() { return glewGetErrorString(0)[0] == 0; }

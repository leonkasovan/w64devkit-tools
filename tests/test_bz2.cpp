#include <bzlib.h>
int main() { return BZ2_bzlibVersion()[0] == 0; }

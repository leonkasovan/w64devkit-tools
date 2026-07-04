#include <wavpack/wavpack.h>
int main() { return WavpackGetLibraryVersionString()[0] == 0; }

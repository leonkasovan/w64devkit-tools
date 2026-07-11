#include <lzma.h>
int main() { return lzma_version_string()[0] == 0; }

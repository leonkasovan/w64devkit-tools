#include <zstd.h>
int main() { return ZSTD_versionString()[0] == 0; }

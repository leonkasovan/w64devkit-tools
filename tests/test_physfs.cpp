#include <physfs.h>
int main() { return PHYSFS_init("test") ? 0 : 1; }

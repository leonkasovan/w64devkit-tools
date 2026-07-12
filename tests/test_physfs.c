#include <physfs.h>
#include <stdio.h>

int main(void) {
    PHYSFS_Version ver;
    PHYSFS_getLinkedVersion(&ver);
    printf("physfs %d.%d.%d\n", ver.major, ver.minor, ver.patch);
    return 0;
}

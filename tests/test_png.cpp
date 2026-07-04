#include <png.h>
int main() { return png_access_version_number() > 0 ? 0 : 1; }

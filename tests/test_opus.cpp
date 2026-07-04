#include <opus/opus.h>
int main() { return opus_get_version_string()[0] == 0; }

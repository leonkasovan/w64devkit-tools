#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
int main() { uint32_t v; pcre2_config(PCRE2_CONFIG_VERSION, &v); return 0; }

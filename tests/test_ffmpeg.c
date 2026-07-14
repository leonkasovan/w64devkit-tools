#include <libavutil/avutil.h>
#include <libavutil/version.h>
#include <stdio.h>

int main(void) {
    unsigned version = avutil_version();
    printf("ffmpeg libavutil %d.%d.%d\n",
           AV_VERSION_MAJOR(version),
           AV_VERSION_MINOR(version),
           AV_VERSION_MICRO(version));

    const char *config = avutil_configuration();
    if (config)
        printf("configuration: %s\n", config);

    return 0;
}

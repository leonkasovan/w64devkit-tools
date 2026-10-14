#include <cJSON.h>
#include <stdio.h>

int main(void) {
    cJSON *root = cJSON_Parse("{\"a\":1}");
    if (!root) {
        fprintf(stderr, "cJSON_Parse failed\n");
        return 1;
    }

    cJSON *a = cJSON_GetObjectItemCaseSensitive(root, "a");
    if (!cJSON_IsNumber(a) || cJSON_GetNumberValue(a) != 1.0) {
        fprintf(stderr, "json value mismatch\n");
        cJSON_Delete(root);
        return 1;
    }

    printf("cJSON %s parsed OK\n", cJSON_Version());
    cJSON_Delete(root);
    return 0;
}

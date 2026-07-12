#include <jansson.h>
#include <stdio.h>

int main(void) {
    json_t *root;
    json_error_t error;

    root = json_loads("{\"a\":1}", 0, &error);
    if (!root) {
        fprintf(stderr, "json_loads failed: %s\n", error.text);
        return 1;
    }

    json_t *a = json_object_get(root, "a");
    if (!json_is_integer(a) || json_integer_value(a) != 1) {
        fprintf(stderr, "json value mismatch\n");
        json_decref(root);
        return 1;
    }

    printf("jansson %s\n", JANSSON_VERSION);
    json_decref(root);
    return 0;
}

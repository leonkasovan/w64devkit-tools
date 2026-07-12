#include <nlohmann/json.hpp>
#include <stdio.h>

using json = nlohmann::json;

int main(void) {
    json j = json::parse("{\"a\":1}");
    printf("nlohmann/json parsed OK\n");
    return j["a"] != 1;
}

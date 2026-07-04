#include <nlohmann/json.hpp>
using json = nlohmann::json;
int main() { json j = json::parse("{\"a\":1}"); return j["a"] != 1; }

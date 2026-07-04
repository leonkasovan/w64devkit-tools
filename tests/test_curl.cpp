#include <curl/curl.h>
int main() { return curl_version()[0] == 0; }

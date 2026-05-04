#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "http_parser.h"

static http_parser parser;
static http_parser_settings settings;

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    http_parser_settings_init(&settings);
    http_parser_init(&parser, HTTP_BOTH);
    http_parser_execute(&parser, &settings, (const char *)data, size);
    return 0;
}

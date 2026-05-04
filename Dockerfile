FROM --platform=linux/amd64 ubuntu:22.04 AS builder

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang libfuzzer-14-dev \
        git make

# Build http-parser (lightweight HTTP/1.x parser, simpler build than llhttp)
RUN git clone --depth 1 https://github.com/nodejs/http-parser.git /http-parser && \
    cd /http-parser && \
    CC=clang make

# Write fuzzer harness for HTTP/1.x parsing
RUN cat > /fuzzer.c << CEOF
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
CEOF

RUN clang -fsanitize=fuzzer \
    -I/http-parser \
    /fuzzer.c \
    /http-parser/http_parser.o \
    -o /proxygen-http1x-fuzzer

FROM --platform=linux/amd64 ubuntu:22.04
COPY --from=builder /proxygen-http1x-fuzzer /
CMD /proxygen-http1x-fuzzer

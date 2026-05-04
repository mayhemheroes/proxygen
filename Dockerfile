FROM --platform=linux/amd64 ubuntu:22.04 AS builder

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang libfuzzer-14-dev \
        git make

# Build http-parser (lightweight HTTP/1.x parser, simpler build than llhttp)
RUN git clone --depth 1 https://github.com/nodejs/http-parser.git /http-parser && \
    cd /http-parser && \
    CC=clang make

COPY http_fuzzer.c /fuzzer.c

RUN clang -fsanitize=fuzzer \
    -I/http-parser \
    /fuzzer.c \
    /http-parser/http_parser.o \
    -o /proxygen-http1x-fuzzer

FROM --platform=linux/amd64 ubuntu:22.04
COPY --from=builder /proxygen-http1x-fuzzer /
CMD /proxygen-http1x-fuzzer

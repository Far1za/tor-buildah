FROM debian:buster AS build

WORKDIR /src

ARG TOR=tor-0.4.6.7
ARG HASH=31728f4ad386042d3088f015e28f15d91ae3e283

RUN apt-get update && apt-get install git automake autoconf build-essential \
    pkg-config libevent-dev libssl-dev zlib1g-dev liblzma-dev libzstd-dev -y

RUN set -ex \
    && git clone https://github.com/torproject/tor.git \
    --depth 1 -b ${TOR} \
    && cd tor \
    && test `git rev-parse HEAD` = ${HASH} || exit 1 \
    && ./autogen.sh \
    && ./configure --prefix=/tor --enable-lzma --enable-zstd \
    --disable-asciidoc --disable-manpage --disable-html-manual \
    && make -j4 \
    && make install

FROM tor-base-image:x86_64
COPY --chown=65532:65532 --from=build /tor /tor
WORKDIR /tor/bin
ENTRYPOINT ["./tor"]

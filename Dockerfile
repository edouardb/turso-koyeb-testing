FROM --platform=$BUILDPLATFORM rust:1 AS builder

WORKDIR /turso

RUN apt update && apt search libclang && apt install git libclang-dev protobuf-compiler -y \
    && git clone --depth 1 https://github.com/libsql/sqld.git .

RUN cargo build --release -j $(nproc)

FROM --platform=$BUILDPLATFORM  debian:stable-slim AS runner

WORKDIR /turso

COPY --from=builder /turso/target/release/sqld sqld
COPY ./docker-entrypoint.sh docker-entrypoint.sh

RUN apt-get update \
    && apt-get install -y jq curl dnsutils \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "./docker-entrypoint.sh" ]
## 
# BUILD STAGE
# ===========
FROM elixir:1.14-alpine AS build

# Install build deps
RUN apk update && \
    apk add --no-cache bash build-base curl git libgcc python3

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV RUSTUP_HOME=/root/.rustup \
    RUSTFLAGS="-C target-feature=-crt-static" \
    CARGO_HOME=/root/.cargo  \
    PATH="/root/.cargo/bin:$PATH"

# Prepare build
WORKDIR /build
ENV HOME=/build
ENV MIX_ENV=prod
ARG force_build_rust=0
ENV RUSTLER_PRECOMPILATION_EXAMPLE_BUILD=${force_build_rust}

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# Compile app
COPY lib lib
COPY priv priv
RUN mix compile
RUN mix release

##
# APP STAGE
# =========
FROM alpine:3.16 AS app

# Runtime deps
RUN apk update && \
    apk add --no-cache bash libgcc libstdc++ ncurses-libs openssl-dev

RUN mkdir /app
WORKDIR /app

COPY --from=build /build/_build/prod/rel/nex ./

CMD ["bin/nex", "start"]

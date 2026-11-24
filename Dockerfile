# TradeCore engine + dashboard in one small container.
# Used by Render (or any Docker host). Build stage compiles the C code and
# runs the full test suite, so a broken build never gets deployed.
FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends gcc make libc6-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY Makefile ./
COPY src ./src
COPY tests ./tests
COPY bench ./bench
RUN make build/tradecore build/test_engine && ./build/test_engine | tail -1

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=build /src/build/tradecore ./tradecore
COPY frontend ./frontend
# The host sets PORT; HOST=0.0.0.0 makes the server reachable from outside the container.
ENV HOST=0.0.0.0 PORT=8080
EXPOSE 8080
CMD ["./tradecore", "--static", "frontend"]

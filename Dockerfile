FROM ghcr.io/astral-sh/uv:python3.12-alpine

RUN apk add --no-cache coreutils

COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

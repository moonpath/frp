ARG BASE_IMAGE="alpine:latest"
ARG VERSION=0.65.0
ARG TARGETARCH=amd64

FROM $BASE_IMAGE AS builder

ARG VERSION
ARG TARGETARCH

RUN wget --no-check-certificate -qO /tmp/frp.tar.gz https://github.com/fatedier/frp/releases/download/v${VERSION}/frp_${VERSION}_linux_${TARGETARCH}.tar.gz && \
    tar xzf /tmp/frp.tar.gz -C /tmp && \
    mv /tmp/frp_${VERSION}_linux_${TARGETARCH} /tmp/frp

FROM ${BASE_IMAGE} AS runtime

COPY --from=builder /tmp/frp/frps /usr//local/bin/
COPY --from=builder /tmp/frp/frpc /usr/local/bin/
COPY --from=builder /tmp/frp/*.toml /frp/

RUN apk add --no-cache ca-certificates

RUN cat <<'EOF' > /usr/local/bin/docker-entrypoint && chmod +x /usr/local/bin/docker-entrypoint
#!/bin/sh
set -e

CMD_PATH=$(command -v "$1" 2>/dev/null || echo "$1")

case "$CMD_PATH" in
  /usr/local/bin/frps|/usr/local/bin/frpc)
    exec "$@"
    ;;
  *)
    echo "Error: invalid command '${1:-<empty>}'" >&2
    echo "Usage: docker run image frps -c /frp/frps.toml" >&2
    echo "   or: docker run image frpc -c /frp/frpc.toml" >&2
    exit 1
    ;;
esac
EOF

HEALTHCHECK --interval=1m --timeout=5s --start-period=10s --retries=3 \
  CMD pgrep "frps|frpc" >/dev/null

EXPOSE 7000/tcp 7000/udp

WORKDIR /frp

ENTRYPOINT ["docker-entrypoint"]
CMD ["frps", "-c", "/frp/frps.toml"]

ARG BASE_IMAGE="ubuntu:24.04"
ARG VERSION=0.65.0
ARG TARGETARCH=amd64

FROM $BASE_IMAGE AS builder

ARG VERSION
ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    curl

RUN curl -fsSLo /tmp/frp.tar.gz https://github.com/fatedier/frp/releases/download/v${VERSION}/frp_${VERSION}_linux_${TARGETARCH}.tar.gz && \
    tar xzf /tmp/frp.tar.gz -C /tmp && \
    mv /tmp/frp_${VERSION}_linux_${TARGETARCH} /tmp/frp

FROM ${BASE_IMAGE}

COPY --from=builder /tmp/frp/frps /usr/bin/
COPY --from=builder /tmp/frp/frpc /usr/bin/
COPY --from=builder /tmp/frp/*.toml /etc/frp/

RUN cat <<'EOF' > /usr/bin/docker-entrypoint && chmod +x /usr/bin/docker-entrypoint
#!/bin/sh
set -e

case "$(command -v "$1" 2>/dev/null || echo "$1")" in
  /usr/bin/frps|/usr/bin/frpc)
    exec "$@"
    ;;
  *)
    echo "Error: invalid command '${1:-<empty>}'" >&2
    echo "Usage: docker run image frps -c /etc/frp/frps.toml" >&2
    echo "   or: docker run image frpc -c /etc/frp/frpc.toml" >&2
    exit 1
    ;;
esac
EOF

EXPOSE 7000/tcp
EXPOSE 7000/udp

WORKDIR /etc/frp

ENTRYPOINT ["docker-entrypoint"]
CMD ["frps", "-c", "/etc/frp/frps.toml"]

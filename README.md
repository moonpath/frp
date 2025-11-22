# Containerized FRP

A secure, production-ready FRP deployment with **mandatory TLS encryption** and **QUIC protocol support**. This setup enforces encrypted connections and token-based authentication to protect your services from unauthorized access.

## Security Features

- **Forced TLS encryption** on all connections
- **QUIC protocol** for improved performance and security
- **Token-based authentication** to prevent unauthorized access
- **Certificate-based trust** with custom CA
- **Isolated containers** for enhanced security

## Quick Start

### 1. Generate SSL Certificates

```bash
export SERVER_DOMAIN="your-server.com"
bash genssl
mkdir -p /etc/frp/ssl
mv *.crt *.key /etc/frp/ssl/
```

### 2. Configure

**Server** (`/etc/frp/frps.toml`):

```toml
bindPort = 7000
quicBindPort = 7000

[auth]
method = "token"
token = "your-secure-token"

[transport.tls]
force = true
certFile = "/etc/frp/ssl/server.crt"
keyFile = "/etc/frp/ssl/server.key"
```

**Client** (`/etc/frp/frpc.toml`):

```toml
serverAddr = "your-server-ip"
serverPort = 7000

[auth]
method = "token"
token = "your-secure-token"

[transport]
protocol = "quic"

[transport.tls]
enable = true
trustedCaFile = "/etc/frp/ssl/ca.crt"

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000
```

### 3. Deploy

```bash
docker compose up -d
```

## Links

- [FRP Repository](https://github.com/fatedier/frp)

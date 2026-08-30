# Traefik Reverse Proxy

A small, reusable Docker Compose setup for running Traefik as a shared reverse proxy. It provides automatic HTTP-to-HTTPS redirects, Let's Encrypt certificates, Docker service discovery, access logs, and a health check.

## Features

- Traefik `v3.7`
- Automatic HTTP-to-HTTPS redirection
- Automatic TLS certificates through Let's Encrypt
- Docker provider with services disabled by default
- Shared external Docker network named `vnet`
- Persistent ACME certificate storage
- Access logging and container health checks
- Anonymous usage reporting disabled

## Prerequisites

- Docker Engine
- Docker Compose v2
- Ports `80` and `443` available on the host
- A domain name whose DNS records point to the server
- A public email address for Let's Encrypt notifications

## Setup

### 1. Create the shared network

The `vnet` network must exist before starting Traefik. Create it once on the server:

```bash
docker network create vnet
```

Traefik and every proxied service must be connected to this network. Traefik uses `vnet` as its default Docker provider network, which also avoids ambiguous routing when an application is connected to multiple networks.

### 2. Configure the environment

Copy the example environment file:

```bash
cp .env.example .env
```

Set your Let's Encrypt email address in `.env`:

```dotenv
LETSENCRYPT_EMAIL=admin@example.com
```

The `.env` file is excluded from version control.

### 3. Start Traefik

```bash
docker compose up -d
```

Check its status and logs:

```bash
docker compose ps
docker compose logs -f traefik
```

## Exposing another service

Connect the service to `vnet` and add Traefik labels. Replace `app.example.com` and port `3000` with the hostname and internal port of your application.

```yaml
services:
  app:
    image: your-image:latest
    restart: unless-stopped
    networks:
      - vnet
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`app.example.com`)"
      - "traefik.http.routers.app.entrypoints=websecure"
      - "traefik.http.routers.app.tls=true"
      - "traefik.http.routers.app.tls.certresolver=letsencrypt"
      - "traefik.http.services.app.loadbalancer.server.port=3000"

networks:
  vnet:
    external: true
    name: vnet
```

Router and service names such as `app` must be unique across containers discovered by the same Traefik instance.

## How it works

Traefik listens on ports `80` and `443`. Requests arriving over HTTP are redirected to HTTPS. For enabled containers on `vnet`, Traefik reads Docker labels, routes requests by hostname, and obtains certificates through the Let's Encrypt HTTP-01 challenge.

Certificate state is stored in `./data/acme.json`. The startup script creates the file when necessary and restricts its permissions to `600`.

## Common commands

```bash
# Start or update the stack
docker compose up -d

# View logs
docker compose logs -f traefik

# Validate the Compose configuration
docker compose config

# Stop the stack
docker compose down
```

Because `vnet` is external, `docker compose down` does not remove it.

## Security notes

- Do not commit `.env` or the `data/` directory.
- Keep ports `80` and `443` reachable for normal traffic and Let's Encrypt validation.
- Only containers with `traefik.enable=true` are exposed.
- The Docker socket is mounted read-only, but access to it is still security-sensitive. Run only trusted containers on the host.
- The Traefik dashboard is not enabled by this configuration.

## Project structure

```text
.
|-- .env.example
|-- .gitignore
|-- docker-compose.yml
`-- runtime/
    `-- entrypoint.sh
```

## License

No license has been specified. Add a license file before distributing or accepting contributions if you want to define reuse terms explicitly.

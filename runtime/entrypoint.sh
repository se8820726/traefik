#!/bin/sh
set -eu

touch /letsencrypt/acme.json
chmod 600 /letsencrypt/acme.json

exec traefik \
    --global.checknewversion=false \
    --global.sendanonymoususage=false \
    --log.level=INFO \
    --accesslog=true \
    --ping=true \
    --entrypoints.web.address=:80 \
    --entrypoints.web.http.redirections.entrypoint.to=websecure \
    --entrypoints.web.http.redirections.entrypoint.scheme=https \
    --entrypoints.websecure.address=:443 \
    --providers.docker=true \
    --providers.docker.exposedbydefault=false \
    --providers.docker.network=vnet \
    --certificatesresolvers.letsencrypt.acme.email="$LETSENCRYPT_EMAIL" \
    --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json \
    --certificatesresolvers.letsencrypt.acme.httpchallenge=true \
    --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web

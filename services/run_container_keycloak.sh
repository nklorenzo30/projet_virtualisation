#!/bin/bash

sudo docker rm -f keycloak 2>/dev/null

KEYCLOAK_OPTS=(
  --name keycloak
  --network mynet
  -d

  # --- DB ---
  -e KC_DB=postgres
  -e KC_DB_URL=jdbc:postgresql://db:5432/keycloak
  -e KC_DB_USERNAME=admin
  -e KC_DB_PASSWORD=admin123

  # --- ADMIN ---
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin

  # --- PROXY (LA CLÉ 🔑) ---
  -e KC_PROXY=edge
  -e KC_HTTP_ENABLED=true
  -e KC_HTTP_RELATIVE_PATH=/auth

  # --- HOST PUBLIC ---
  -e KC_HOSTNAME=localhost
  -e KC_HOSTNAME_PATH=/auth
  -e KC_HOSTNAME_STRICT=false
  -e KC_HOSTNAME_STRICT_HTTPS=false

  # --- TRAEFIK ---
  -l "traefik.enable=true"
  -l "traefik.http.routers.keycloak.rule=Host(\`localhost\`) && PathPrefix(\`/auth\`)"
  -l "traefik.http.routers.keycloak.entrypoints=websecure"
  -l "traefik.http.routers.keycloak.tls=true"
  -l "traefik.http.services.keycloak.loadbalancer.server.port=8080"
)

sudo docker run "${KEYCLOAK_OPTS[@]}" quay.io/keycloak/keycloak:26.4.7   start


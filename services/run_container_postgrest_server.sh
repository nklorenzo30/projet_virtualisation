#!/bin/bash

# Nettoyage
sudo docker rm -f postgrest 2>/dev/null

PGRST_OPTS=(
  --name postgrest
  --network mynet
  -d  

  # --- CONFIGURATION BASE DE DONNÉES ---
  -e PGRST_DB_URI="postgres://admin:admin123@db:5432/app_db"
  -e PGRST_DB_ANON_ROLE="anon"
  -e PGRST_DB_SCHEMA="public"
  # --- SÉCURITÉ JWT (Correction ici) ---
  # On pointe vers l'endpoint interne de Keycloak pour récupérer les clés de validation
  # --- LABELS TRAEFIK ---
  -l "traefik.enable=true"
  -l "traefik.http.routers.postgrest.rule=Host(\`localhost\`) && PathPrefix(\`/api\`)"
  -l "traefik.http.routers.postgrest.entrypoints=websecure"
  -l "traefik.http.routers.postgrest.tls=true"
  -l "traefik.http.routers.postgrest.middlewares=auth-proxy@docker,strip-api@docker" 
  -l "traefik.http.middlewares.strip-api.stripprefix.prefixes=/api" 
  -l "traefik.http.middlewares.auth-proxy.forwardauth.address=http://oauth2-proxy:4180"
  -l "traefik.http.middlewares.auth-proxy.forwardauth.trustForwardHeader=true"
  -l "traefik.http.middlewares.auth-proxy.forwardauth.authResponseHeaders=X-Auth-Request-Access-Token,Authorization,X-Auth-Request-User,X-Auth-Request-Email"
  -l "traefik.http.services.postgrest.loadbalancer.server.port=3000"
)

sudo docker run "${PGRST_OPTS[@]}" postgrest/postgrest

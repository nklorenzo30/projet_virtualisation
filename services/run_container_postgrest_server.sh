#!/bin/bash

# 1. Nettoyage
sudo docker rm -f postgrest 2>/dev/null

# 2. Définition du tableau
PGRST_OPTS=(
  --name postgrest
  --network mynet
  -d
  -p 3001:3000

  # --- CONFIGURATION DB ---
  -e PGRST_DB_URI="postgres://admin:admin123@db:5432/app_db"
  -e PGRST_DB_SCHEMA="public"
  -e PGRST_DB_ANON_ROLE="anon"

  # --- CONFIGURATION JWT (Keycloak) ---
  -e PGRST_ROLE_CLAIM_KEY=".resource_access.\"traefik-client\".roles[0]"
  -e PGRST_JWT_JWKS_URI="http://keycloak:8080/auth/realms/myrealm/protocol/openid-connect/certs"

  # --- LABELS TRAEFIK ---
  -l "traefik.enable=true"
  -l "traefik.http.routers.postgrest.rule=Host(\`localhost\`) && PathPrefix(\`/api\`)"
  -l "traefik.http.routers.postgrest.entrypoints=websecure"
  -l "traefik.http.routers.postgrest.tls=true"

  # UNIQUEMENT StripPrefix (PAS d’auth ici)
  -l "traefik.http.routers.postgrest.middlewares=postgrest-strip@docker"
  -l "traefik.http.middlewares.postgrest-strip.stripprefix.prefixes=/api"

  -l "traefik.http.services.postgrest.loadbalancer.server.port=3000"
)

# 3. Lancement
echo "🚀 Démarrage de PostgREST (auth déjà faite sur /)"
sudo docker run "${PGRST_OPTS[@]}" postgrest/postgrest

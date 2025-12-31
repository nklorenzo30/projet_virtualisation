#!/bin/bash

# Nettoyage
sudo docker rm -f postgrest 2>/dev/null

PGRST_OPTS=(
  --name postgrest
  --network mynet
  -d

  # --- CONFIGURATION BASE DE DONNÉES ---
  # On pointe vers le conteneur 'db' et la base 'app_db'
  -e PGRST_DB_URI="postgres://admin:admin123@db:5432/app_db"
  -e PGRST_DB_SCHEMA="public"
  
  # Rôle utilisé pour les requêtes publiques (si non authentifié)
  -e PGRST_DB_ANON_ROLE="anon"
  
  # Configuration pour que PostgREST fasse confiance aux rôles passés par le Proxy
  -e PGRST_DB_ROOT_SPEC="web_user"

  # --- LABELS TRAEFIK (PROTECTION HTTPS) ---
  -l "traefik.enable=true"
  
  # Route pour accéder aux utilisateurs
  -l "traefik.http.routers.postgrest.rule=PathPrefix(\`/api\`)"
  
  # Utilisation de l'entrypoint HTTPS
  -l "traefik.http.routers.postgrest.entrypoints=websecure"
  -l "traefik.http.routers.postgrest.tls=true"
  
  # --- LE VERROU : MIDDLEWARE ---
  # On attache ici le middleware 'auth-proxy' que nous allons créer avec oauth2-proxy
  -l "traefik.http.routers.postgrest.middlewares=auth-proxy@docker"
  
  -l "traefik.http.services.postgrest.loadbalancer.server.port=3000"
)

sudo docker run "${PGRST_OPTS[@]}" postgrest/postgrest

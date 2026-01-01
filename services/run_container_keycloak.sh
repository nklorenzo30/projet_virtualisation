#!/bin/bash

sudo docker rm -f keycloak 2>/dev/null

KEYCLOAK_OPTS=(
  --name keycloak
  --network mynet
  -d
  # Type de base de données
  -e KC_DB=postgres

  # URL de connexion (Utilise le nom du conteneur DB sur le réseau Docker)
  -e KC_DB_URL="jdbc:postgresql://db:5432/keycloak"

  # Identifiants
  -e KC_DB_USERNAME=admin
  -e KC_DB_PASSWORD=admin123
  -e KC_DB_DATABASE=keycloak
  # --- ADMIN ---
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin

  # --- PROXY & RÉSEAU ---
  -e KC_HTTP_ENABLED=true
  -e KC_HTTP_RELATIVE_PATH=/auth
  -e KC_PROXY_HEADERS=xforwarded
  
  # --- HOSTNAME PUBLIC (Correction ici) ---
  # On utilise KC_HOSTNAME pour définir le domaine
  -e KC_HOSTNAME=localhost
  # On force l'URL complète pour éviter que Keycloak ne devine mal le port
  -e KC_HOSTNAME_URL=https://localhost/auth
  -e KC_HOSTNAME_STRICT=true
  -e KC_HOSTNAME_STRICT_HTTPS=true

  # --- LABELS TRAEFIK ---
  -l "traefik.enable=true"
  -l "traefik.http.routers.keycloak.rule=Host(\`localhost\`) && PathPrefix(\`/auth\`)"
  -l "traefik.http.routers.keycloak.entrypoints=websecure"
  -l "traefik.http.routers.keycloak.tls=true"
  -l "traefik.http.services.keycloak.loadbalancer.server.port=8080"
)

# On garde start-dev mais on s assure que les variables d environnement prennent le dessus
sudo docker run "${KEYCLOAK_OPTS[@]}" quay.io/keycloak/keycloak:latest start 

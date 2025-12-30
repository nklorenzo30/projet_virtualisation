#!/bin/bash

sudo docker rm -f keycloak 2>/dev/null

KEYCLOAK_ARGS=(
  --name keycloak
  --network mynet
  -v keycloak_data:/opt/keycloak/data
  
  # --- COMPTES ADMIN (Nouvelle syntaxe Keycloak 26) ---
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin
  
  # --- CONFIGURATION RÉSEAU & PROXY ---
  
  # 1. Active l'écoute HTTP interne (car Traefik gère le HTTPS devant)
  -e KC_HTTP_ENABLED=true
  
  # Dit à Keycloak de lire les headers X-Forwarded envoyés par Traefik
  -e KC_PROXY_HEADERS=xforwarded
  
  
  # 4. Le chemin relatif
  -e KC_HTTP_RELATIVE_PATH=/auth
  
  # 5. Désactive la vérification stricte (utile en dev local)
  -e KC_HOSTNAME_STRICT=false
  -e KC_HOSTNAME_STRICT_HTTPS=false
  
  # --- TRAEFIK ---
  -l "traefik.enable=true"
  # On route le Path /auth
  -l "traefik.http.routers.keycloak.rule=PathPrefix(\`/auth\`)"
  -l "traefik.http.services.keycloak.loadbalancer.server.port=8080"
  
  # --- IMAGE ---
  quay.io/keycloak/keycloak:26.4.7
  
  # --- COMMANDE ---
  start-dev
  --import-realm
)

sudo docker run -d "${KEYCLOAK_ARGS[@]}"


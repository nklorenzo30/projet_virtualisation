#!/bin/bash

# Nettoyage
sudo docker rm -f web 2>/dev/nul
WEB_ARGS=(
  --name web
  --network mynet
  
  # --- LABELS TRAEFIK ---
  -l "traefik.enable=true"
  
  # Règle : Tout ce qui commence par / va ici
  -l "traefik.http.routers.web.rule=PathPrefix(\`/\`)"

  -l "traefik.http.routers.web.entrypoints=https"
 
  # Port interne de Nginx
  -l "traefik.http.services.web.loadbalancer.server.port=80"
  
  # --- IMAGE ---
  -d nginx
)

sudo docker run "${WEB_ARGS[@]}"

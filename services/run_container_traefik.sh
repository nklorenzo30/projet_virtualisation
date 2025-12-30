#!/bin/bash
# Nettoyage
sudo docker rm -f traefik 2>/dev/nul
# 1. On définit tous les arguments dans une liste (tableau)
TRAEFIK_ARGS=(
  --name traefik
  --network mynet
  
  # --- PORTS ---
  -p 80:80
  -p 443:443
  -p 8080:8080 # Dashboard
  
  # --- VOLUMES ---
  -v /var/run/docker.sock:/var/run/docker.sock
  -v $(pwd)/certs:/certs
  -v $(pwd)/dynamic_conf.yml:/dynamic_conf.yml
  
  # --- IMAGE ---
  traefik:v3.6.2
  
  # --- CONFIGURATION TRAEFIK ---
  --api.insecure=true
  --providers.docker=true
  --providers.docker.exposedbydefault=false
  --providers.file.filename=/dynamic_conf.yml
  
  # --- ENTRYPOINTS HTTP (:80) ---
  --entrypoints.http.address=:80
  # Redirection automatique vers HTTPS
  --entrypoints.http.http.redirections.entrypoint.to=http
  --entrypoints.http.http.redirections.entrypoint.scheme=http
  
  # --- ENTRYPOINTS HTTPS (:443) ---
  --entrypoints.https.address=:443
  # TLS activé par défaut (utilise dynamic_conf.yml)
  --entrypoints.https.http.tls=true
  # --- METRICS ET API ---
  --metrics.prometheus=true
  --metrics.prometheus.entrypoint=metrics
  --entrypoints.metrics.address=:9000
)

# 2. On lance la commande en appelant le tableau
sudo docker run -d "${TRAEFIK_ARGS[@]}"


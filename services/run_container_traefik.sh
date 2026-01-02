#!/bin/bash
sudo docker network create mynet 2>/dev/null || true
sudo docker rm -f traefik 2>/dev/null

# 1. Options Docker (Avant l'image)
DOCKER_OPTS=(
  --name traefik
  --network mynet
  -d
  -p 80:80
  -p 443:443
  -p 8080:8080
  -v /var/run/docker.sock:/var/run/docker.sock
  -v $(pwd)/certs:/certs
  -v $(pwd)/dynamic_conf.yml:/dynamic_conf.yml
)

# 2. Arguments Traefik (Après l'image)
TRAEFIK_ARGS=(
  --api.insecure=true
  --providers.docker=true
  --providers.docker.exposedbydefault=false
  --providers.file.filename=/dynamic_conf.yml
 
  # Configuration Entrypoints
 # --entrypoints.web.address=:80
  --entrypoints.websecure.address=:443
  
  # Redirection HTTP -> HTTPS globale
 # --entrypoints.web.http.redirections.entrypoint.to=websecure
  #--entrypoints.web.http.redirections.entrypoint.scheme=https
  
  # Activation TLS par défaut sur le port 443
  --entrypoints.websecure.http.tls=true
)

# Exécution : docker run [OPTIONS] IMAGE [ARGUMENTS TRAEFIK]
sudo docker run "${DOCKER_OPTS[@]}" traefik:v3.6.2 "${TRAEFIK_ARGS[@]}"

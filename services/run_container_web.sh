#!/bin/bash
sudo docker rm -f web1 2>/dev/nul
WEB_ARGS=(
  --name web1
  --network mynet
  -d
  -l "traefik.enable=true"
  -l "traefik.http.routers.web2.rule=Host(\`localhost\`) && PathPrefix(\`/\`)"
  # On s'aligne sur les noms déclarés dans Traefik
  -l "traefik.http.routers.web2.entrypoints=websecure" 
  -l "traefik.http.routers.web2.tls=true" 
  -l "traefik.http.services.web2.loadbalancer.server.port=80"
  nginx
)
sudo docker run "${WEB_ARGS[@]}"

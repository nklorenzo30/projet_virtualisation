#!/bin/bash
sudo docker rm -f web 2>/dev/nul
WEB_ARGS=(
  --name web
  --network mynet
  -d
  -l "traefik.enable=true"
  -l "traefik.http.routers.web.rule=Host(\`localhost\`) && PathPrefix(\`/\`)"
  # On s'aligne sur les noms déclarés dans Traefik
  -l "traefik.http.routers.web.entrypoints=web,websecure" 
  -l "traefik.http.services.web.loadbalancer.server.port=80"
  nginx
)
sudo docker run "${WEB_ARGS[@]}"

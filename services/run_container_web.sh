#!/bin/bash
sudo docker rm -f web 2>/dev/null

WEB_ARGS=(
  --name web
  --network mynet
  -d

  -l "traefik.enable=true"
  -l "traefik.http.routers.web.rule=Host(\`localhost\`) && PathPrefix(\`/\`)"
  -l "traefik.http.routers.web.entrypoints=websecure"
  -l "traefik.http.routers.web.tls=true"

  # ON ATTACHE LE MIDDLEWARE AU ROUTER
  -l "traefik.http.routers.web.middlewares=web-auth@docker"

  -l "traefik.http.services.web.loadbalancer.server.port=80"
  -l "traefik.http.routers.web1.middlewares=web-auth"
  -l "traefik.http.middlewares.web-auth.forwardauth.address=http://oauth2-proxy:4180"
  -l "traefik.http.middlewares.web-auth.forwardauth.trustForwardHeader=true"
  -l "traefik.http.middlewares.web-auth.forwardauth.authResponseHeaders=X-Auth-Request-Access-Token,Authorization,X-Auth-Request-User"

  nginx
)

sudo docker run "${WEB_ARGS[@]}"

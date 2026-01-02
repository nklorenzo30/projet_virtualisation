#!/bin/bash
# Suppression du conteneur si existant
sudo docker rm -f web1 2>/dev/null

# Définition des options Docker
WEB_ARGS=(
  --name web1
  --network mynet
  -d

  # --- Labels Traefik ---
  -l "traefik.enable=true"
  # Router pour / sur localhost
  -l "traefik.http.routers.web1.rule=Host(\`localhost\`) && PathPrefix(\`/\`)"
  -l "traefik.http.routers.web1.entrypoints=websecure"
  -l "traefik.http.routers.web1.tls=true"
  # Middleware pour OAuth2 Proxy (défini via labels Docker)
  -l "traefik.http.routers.web1.middlewares=web-auth@docker"
  -l "traefik.http.services.web1.loadbalancer.server.port=80"

  # --- Middleware OAuth2 Proxy ---
  -l "traefik.http.middlewares.web-auth.forwardauth.address=http://oauth2-proxy:4180"
  -l "traefik.http.middlewares.web-auth.forwardauth.trustForwardHeader=true"
  -l "traefik.http.middlewares.web-auth.forwardauth.authResponseHeaders=X-Auth-Request-User,X-Auth-Request-Email"

  # Image Nginx avec un index.html par défaut
  nginx
)

# Lancement du conteneur
sudo docker run "${WEB_ARGS[@]}"

echo "Conteneur Nginx avec OAuth2 Proxy démarré sur https://localhost/"

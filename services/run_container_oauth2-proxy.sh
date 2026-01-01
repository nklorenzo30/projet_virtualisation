#!/bin/bash

# -----------------------------
# Génération d'un secret pour les cookies
# -----------------------------
COOKIE_SECRET=$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-32)

# -----------------------------
# Nettoyage : suppression du conteneur existant
# -----------------------------
sudo docker rm -f oauth2-proxy 2>/dev/null

# -----------------------------
# Arguments Docker dans un tableau
# -----------------------------
OPTS=(
  --name oauth2-proxy
  --network mynet
  -d
  -v $(pwd)/oauth2-proxy.cfg:/etc/oauth2-proxy.cfg

  # Variables d'environnement OAuth2-Proxy / Keycloak
  -e OAUTH2_PROXY_PROVIDER=keycloak-oidc
  -e OAUTH2_PROXY_CLIENT_ID=traefik-client
  -e OAUTH2_PROXY_CLIENT_SECRET="i6AuQYGuHUP7ZqHLJcq2EhAFlJaHHdpF"
  -e OAUTH2_PROXY_COOKIE_SECRET=$COOKIE_SECRET
  -e OAUTH2_PROXY_OIDC_ISSUER_URL=http://keycloak:8080/auth/realms/myrealm
  -e OAUTH2_PROXY_COOKIE_SECURE=true
  -e OAUTH2_PROXY_REDIRECT_URL=https://localhost/oauth2/callback
  -e OAUTH2_PROXY_EMAIL_DOMAINS=*
  -e OAUTH2_PROXY_HTTP_ADDRESS=0.0.0.0:4180

  # Labels Traefik
  -l "traefik.enable=true"
  -l "traefik.http.routers.oauth2.rule=Host(\`localhost\`) && PathPrefix(\`/oauth2\`)"
  -l "traefik.http.routers.oauth2.entrypoints=websecure"
  -l "traefik.http.routers.oauth2.tls=true"

  # Middleware pour PostgREST
  -l "traefik.http.middlewares.auth-proxy.forwardauth.address=http://oauth2-proxy:4180"
  -l "traefik.http.middlewares.auth-proxy.forwardauth.trustForwardHeader=true"
  -l "traefik.http.middlewares.auth-proxy.forwardauth.authResponseHeaders=X-Auth-Request-Access-Token,Authorization"
)

# -----------------------------
# Lancement du conteneur
# -----------------------------
sudo docker run "${OPTS[@]}" quay.io/oauth2-proxy/oauth2-proxy:latest --config=/etc/oauth2-proxy.cfg

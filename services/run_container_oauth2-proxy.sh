#!/bin/bash

COOKIE_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

sudo docker rm -f oauth2-proxy 2>/dev/null

OPTS=(
  --name oauth2-proxy
  --network mynet
  -d
  
  -e OAUTH2_PROXY_PROVIDER=keycloak-oidc
  -e OAUTH2_PROXY_CLIENT_ID=traefik-client
  -e OAUTH2_PROXY_CLIENT_SECRET="cXKf6YLJJtMrt6VmWS9gFnyCfjDQmqRf"

  # --- CORRECTION ICI ---
  # Le proxy utilise le réseau Docker pour l'initialisation (Interne)
  -e OAUTH2_PROXY_OIDC_ISSUER_URL=https://localhost/auth/realms/myrealm

  
  # On désactive la vérification stricte de l issuer car l URL interne (http) 
  # ne correspondra pas à l'URL externe (https://localhost)
  -e OAUTH2_PROXY_INSECURE_OIDC_SKIP_ISSUER_VERIFICATION=true
  -e OAUTH2_PROXY_SSL_INSECURE_SKIP_VERIFY=true

  # On force les URLs pour le NAVIGATEUR (Externe)
  -e OAUTH2_PROXY_LOGIN_URL=https://localhost/auth/realms/master/protocol/openid-connect/auth
  -e OAUTH2_PROXY_REDEEM_URL=http://keycloak:8080/auth/realms/master/protocol/openid-connect/token
  -e OAUTH2_PROXY_VALIDATE_URL=http://keycloak:8080/auth/realms/master/protocol/openid-connect/userinfo
  
  # Configuration Cookies & Redirect
  -e OAUTH2_PROXY_COOKIE_SECRET=$COOKIE_SECRET
  -e OAUTH2_PROXY_COOKIE_SECURE=true
  -e OAUTH2_PROXY_REDIRECT_URL=https://localhost/oauth2/callback
  -e OAUTH2_PROXY_EMAIL_DOMAINS=*
  -e OAUTH2_PROXY_HTTP_ADDRESS=0.0.0.0:4180

  # Labels Traefik
  -l "traefik.enable=true"
  -l "traefik.http.routers.oauth2.rule=PathPrefix(\`/oauth2\`)"
  -l "traefik.http.routers.oauth2.entrypoints=websecure"
  -l "traefik.http.routers.oauth2.tls=true"
  
  -l "traefik.http.middlewares.auth-proxy.forwardauth.address=http://oauth2-proxy:4180"
  -l "traefik.http.middlewares.auth-proxy.forwardauth.trustForwardHeader=true"
  -l "traefik.http.middlewares.auth-proxy.forwardauth.authResponseHeaders=X-Auth-Request-Access-Token,Authorization"
  
  -l "traefik.http.services.oauth2.loadbalancer.server.port=4180"
)

sudo docker run "${OPTS[@]}" quay.io/oauth2-proxy/oauth2-proxy:latest

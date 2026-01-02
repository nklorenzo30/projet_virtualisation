#!/bin/bash

# 1. Génération du secret de session (32 caractères)
COOKIE_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

# 2. Nettoyage
sudo docker rm -f oauth2-proxy 2>/dev/null

# 3. Définition du tableau d'options
# Note : Chaque élément du tableau est une chaîne propre pour Docker
OPTS=(
  --name oauth2-proxy
  --network mynet
  -d

  # --- CONFIGURATION OIDC & KEYCLOAK ---
  -e OAUTH2_PROXY_PROVIDER="keycloak-oidc"
  -e OAUTH2_PROXY_CLIENT_ID="traefik-client"
  -e OAUTH2_PROXY_CLIENT_SECRET="XCZdmj39fKdpFag9kTV6GZU1HmB8ezhv"
  -e OAUTH2_PROXY_OIDC_ISSUER_URL="http://keycloak:8080/auth/realms/myrealm"
  -e OAUTH2_PROXY_SKIP_OIDC_DISCOVERY=true

  # --- ENDPOINTS DE FLUX ---
  -e OAUTH2_PROXY_LOGIN_URL="https://localhost/auth/realms/myrealm/protocol/openid-connect/auth"
  -e OAUTH2_PROXY_REDEEM_URL="http://keycloak:8080/auth/realms/myrealm/protocol/openid-connect/token"
  -e OAUTH2_PROXY_VALIDATE_URL="http://keycloak:8080/auth/realms/myrealm/protocol/openid-connect/userinfo"
  -e OAUTH2_PROXY_OIDC_JWKS_URL="http://keycloak:8080/auth/realms/myrealm/protocol/openid-connect/certs"

  # --- TRANSMISSION DU JETON (Pour PostgREST) ---
  -e OAUTH2_PROXY_SET_AUTHORIZATION_HEADER="true"
  -e OAUTH2_PROXY_PASS_ACCESS_TOKEN="true"

  # --- SÉCURITÉ ET BYPASS ---
  -e OAUTH2_PROXY_INSECURE_OIDC_SKIP_ISSUER_VERIFICATION="true"
  -e OAUTH2_PROXY_SSL_INSECURE_SKIP_VERIFY="true"
  -e OAUTH2_PROXY_SKIP_PROVIDER_BUTTON="true" 
  -e OAUTH2_PROXY_SKIP_JWT_BEARER_TOKENS="true"


  # --- COOKIE ET RÉSEAU ---
  -e OAUTH2_PROXY_COOKIE_SECRET="$COOKIE_SECRET"
  -e OAUTH2_PROXY_COOKIE_SECURE="false"
  -e OAUTH2_PROXY_COOKIE_DOMAINS="localhost"
  -e OAUTH2_PROXY_REDIRECT_URL="https://localhost/oauth2/callback"
  # Autoriser le token d’audience web_user
  #-e OAUTH2_PROXY_OIDC_EXTRA_AUDIENCES=web_user
  -e OAUTH2_PROXY_EXTRA_AUD=web_user
  -e OAUTH2_PROXY_EMAIL_DOMAINS="*"
  -e OAUTH2_PROXY_HTTP_ADDRESS="0.0.0.0:4180"
  -e OAUTH2_PROXY_SKIP_AUTH_PREFLIGHT="true"
  -e OAUTH2_PROXY_ALLOWED_GROUPS="" # Laissez vide pour test
  # --- LABELS TRAEFIK ---
  -l "traefik.enable=true"
  -l "traefik.http.routers.oauth2.rule=Host(\`localhost\`) && PathPrefix(\`/oauth2\`)"
  -l "traefik.http.routers.oauth2.entrypoints=websecure"
  -l "traefik.http.routers.oauth2.tls=true"
  -l "traefik.http.services.oauth2.loadbalancer.server.port=4180"
)

# 4. Lancement avec expansion du tableau
sudo docker run "${OPTS[@]}" quay.io/oauth2-proxy/oauth2-proxy:v7.6.0 

#!/bin/bash
#
# Script de deploiement OAuth2-Proxy
# ===================================
# 
# Ce script configure et lance OAuth2-Proxy comme proxy d'authentification
# pour l'architecture web securisee. OAuth2-Proxy sert d'intermediaire entre
# Traefik et les services backend (Nginx web + PostgREST API).
#
# Fonctionnalites principales :
# - Authentification OIDC via Keycloak
# - Protection des routes web et API
# - Transmission des tokens d'authentification
# - Integration avec Traefik via labels
#
# Prerequis :
# - Reseau Docker 'mynet' existant
# - Keycloak configure avec realm 'myrealm' et client 'traefik-client'
# - Traefik en cours d'execution
#

# Configuration du secret de cookie (32 caracteres requis)
# Ce secret est partage entre toutes les instances OAuth2-Proxy
COOKIE_SECRET="abcdefghijklmnopqrstuvwxyz123456"

# Nettoyage : suppression du conteneur existant s'il existe
sudo docker rm -f oauth2-proxy 2>/dev/null

# Configuration des options Docker
# Utilisation d'un tableau pour une meilleure lisibilite et maintenance
OPTS=(
  # Configuration de base du conteneur
  --name oauth2-proxy                    # Nom du conteneur
  --network mynet                        # Reseau Docker partage
  -d                                     # Mode detache (arriere-plan)

  # === CONFIGURATION OIDC & KEYCLOAK ===
  # Configuration du fournisseur d'identite Keycloak
  -e OAUTH2_PROXY_PROVIDER="keycloak-oidc"                                          # Type de fournisseur OIDC
  -e OAUTH2_PROXY_CLIENT_ID="traefik-client"                                        # ID client Keycloak
  -e OAUTH2_PROXY_CLIENT_SECRET="à définir"                # Secret client Keycloak
  -e OAUTH2_PROXY_OIDC_ISSUER_URL="http://keycloak:8080/auth/realms/myrealm"       # URL de l'emetteur OIDC
  -e OAUTH2_PROXY_SKIP_OIDC_DISCOVERY=true                                         # Desactive la decouverte auto

  # === ENDPOINTS DE FLUX D'AUTHENTIFICATION ===
  # Configuration manuelle des endpoints Keycloak (car discovery desactivee)
  -e OAUTH2_PROXY_LOGIN_URL="https://localhost/auth/realms/myrealm/protocol/openid-connect/auth"      # Page de connexion
  -e OAUTH2_PROXY_REDEEM_URL="http://keycloak:8080/auth/realms/myrealm/protocol/openid-connect/token"   # Echange code->token
  -e OAUTH2_PROXY_VALIDATE_URL="http://keycloak:8080/auth/realms/myrealm/protocol/openid-connect/userinfo" # Validation token
  -e OAUTH2_PROXY_OIDC_JWKS_URL="http://keycloak:8080/auth/realms/myrealm/protocol/openid-connect/certs"   # Cles de verification JWT

  # === TRANSMISSION DES TOKENS ===
  # Configuration pour transmettre les tokens aux services backend (PostgREST)
  -e OAUTH2_PROXY_SET_AUTHORIZATION_HEADER="true"                                   # Ajoute header Authorization
  -e OAUTH2_PROXY_PASS_ACCESS_TOKEN="true"                                         # Transmet le token d'acces

  # === CONFIGURATION DE SECURITE ===
  # Options de securite et contournements pour l'environnement de developpement
  -e OAUTH2_PROXY_INSECURE_OIDC_SKIP_ISSUER_VERIFICATION="true"                    # Ignore la verification de l'emetteur
  -e OAUTH2_PROXY_SSL_INSECURE_SKIP_VERIFY="true"                                  # Ignore la verification SSL
  -e OAUTH2_PROXY_SKIP_PROVIDER_BUTTON="true"                                      # Redirection auto vers Keycloak
  -e OAUTH2_PROXY_SKIP_JWT_BEARER_TOKENS="true"                                    # Ignore les tokens JWT Bearer

  # === CONFIGURATION COOKIES ET RESEAU ===
  # Parametres de cookies et configuration reseau
  -e OAUTH2_PROXY_COOKIE_SECRET="$COOKIE_SECRET"
  -e OAUTH2_PROXY_COOKIE_SECURE="true"
  -e OAUTH2_PROXY_COOKIE_DOMAINS="localhost"
  -e OAUTH2_PROXY_REDIRECT_URL="https://localhost/oauth2/callback"
  # Autoriser le token d’audience web_user
  #-e OAUTH2_PROXY_OIDC_EXTRA_AUDIENCES=web_user
  -e OAUTH2_PROXY_EXTRA_AUD=web_user
  -e OAUTH2_PROXY_EMAIL_DOMAINS="*"
  -e OAUTH2_PROXY_HTTP_ADDRESS="0.0.0.0:4180"
  # Upstream direct vers le conteneur web
  -e OAUTH2_PROXY_UPSTREAMS="http://web1:80"
  -e OAUTH2_PROXY_SKIP_AUTH_PREFLIGHT="true"
  -e OAUTH2_PROXY_ALLOWED_GROUPS="" # Laissez vide pour test
  # === LABELS TRAEFIK ===
  # Configuration de l'integration avec Traefik reverse proxy
  -l "traefik.enable=true"                                                         # Active Traefik pour ce conteneur
  
  # Router principal : gere l'interface web (priorite basse)
  -l "traefik.http.routers.oauth2-main.rule=Host(\`localhost\`)"                  # Route pour l'interface web
  -l "traefik.http.routers.oauth2-main.entrypoints=websecure"                     # Point d'entree HTTPS
  -l "traefik.http.routers.oauth2-main.tls=true"                                  # Active TLS
  -l "traefik.http.routers.oauth2-main.priority=1"                                # Priorite basse (defaut)
  
  # Router d'authentification : gere les endpoints OAuth2 (priorite haute)
  -l "traefik.http.routers.oauth2-auth.rule=Host(\`localhost\`) && PathPrefix(\`/oauth2\`)" # Routes OAuth2 specifiques
  -l "traefik.http.routers.oauth2-auth.entrypoints=websecure"                     # Point d'entree HTTPS
  -l "traefik.http.routers.oauth2-auth.tls=true"                                  # Active TLS
  -l "traefik.http.routers.oauth2-auth.priority=10"                               # Priorite haute (traite en premier)
  
  # Service unique : les deux routers pointent vers le meme service
  -l "traefik.http.services.oauth2-proxy.loadbalancer.server.port=4180"          # Port du service OAuth2-Proxy
)

# Lancement du conteneur OAuth2-Proxy
# Utilise l'image officielle v7.6.0 avec toutes les options configurees
echo "Demarrage d'OAuth2-Proxy..."
sudo docker run "${OPTS[@]}" quay.io/oauth2-proxy/oauth2-proxy:v7.6.0

echo "OAuth2-Proxy demarre et configure pour :"
echo "  - Interface web : https://localhost/"
echo "  - Endpoints OAuth2 : https://localhost/oauth2/*"
echo "  - Middleware d'auth pour PostgREST" 

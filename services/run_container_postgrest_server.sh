#!/bin/bash
#
# Script de deploiement PostgREST avec authentification OAuth2-Proxy
# ==================================================================
#
# Ce script configure et lance PostgREST comme API REST automatique
# pour PostgreSQL. L'API est protegee par OAuth2-Proxy via un middleware
# Traefik et accessible sur https://localhost/api/
#
# Fonctionnalites principales :
# - API REST automatique pour PostgreSQL
# - Authentification via middleware OAuth2-Proxy
# - Integration Traefik avec StripPrefix
# - Transmission des headers d'authentification
#
# Prerequis :
# - Base de donnees PostgreSQL 'app_db' accessible
# - OAuth2-Proxy configure et en cours d'execution
# - Traefik avec middleware web-auth configure
#

# Nettoyage : suppression du conteneur existant s'il existe
sudo docker rm -f postgrest 2>/dev/null

# Configuration des options Docker
# Utilisation d'un tableau pour une meilleure organisation
PGRST_OPTS=(
  # Configuration de base du conteneur
  --name postgrest               # Nom du conteneur
  --network mynet                # Reseau Docker partage
  -d                             # Mode detache (arriere-plan)
  # Note: Pas d'exposition directe de port - acces via Traefik uniquement

  # === CONFIGURATION BASE DE DONNEES ===
  # Parametres de connexion a PostgreSQL
  -e PGRST_DB_URI="postgres://admin:admin123@db:5432/app_db"                       # URI de connexion PostgreSQL
  -e PGRST_DB_SCHEMA="public"                                                      # Schema par defaut
  -e PGRST_DB_ANON_ROLE="anon"                                                     # Role anonyme par defaut

  # === CONFIGURATION D'AUTHENTIFICATION ===
  # JWT desactive - l'authentification est geree par OAuth2-Proxy en amont
  # PostgREST recoit les requetes deja authentifiees via le middleware Traefik

  # === CONFIGURATION TRAEFIK ===
  # Labels pour l'integration avec Traefik reverse proxy
  -l "traefik.enable=true"
  -l "traefik.http.routers.postgrest.rule=Host(\`localhost\`) && PathPrefix(\`/api\`)"
  -l "traefik.http.routers.postgrest.entrypoints=websecure"
  -l "traefik.http.routers.postgrest.tls=true"

  # UNIQUEMENT StripPrefix (PAS d’auth ici)
  # Auth via middleware OAuth2-Proxy + StripPrefix (respecte le diagramme)
  -l "traefik.http.routers.postgrest.middlewares=web-auth@docker,postgrest-strip@docker"  # Middlewares appliques
  -l "traefik.http.middlewares.postgrest-strip.stripprefix.prefixes=/api"         # Supprime /api du chemin
  
  # === MIDDLEWARE D'AUTHENTIFICATION OAUTH2-PROXY ===
  # Configuration du middleware de forward auth vers OAuth2-Proxy
  -l "traefik.http.middlewares.web-auth.forwardauth.address=http://oauth2-proxy:4180/oauth2/auth"  # Endpoint d'auth
  -l "traefik.http.middlewares.web-auth.forwardauth.trustForwardHeader=true"      # Fait confiance aux headers
  # Headers de reponse d'auth transmis a PostgREST (informations utilisateur)
  -l "traefik.http.middlewares.web-auth.forwardauth.authResponseHeaders=X-Auth-Request-User,X-Auth-Request-Email,X-Auth-Request-Access-Token"
  # Headers de requete transmis a OAuth2-Proxy (contexte de la requete)
  -l "traefik.http.middlewares.web-auth.forwardauth.authRequestHeaders=X-Forwarded-Method,X-Forwarded-Proto,X-Forwarded-Host,X-Forwarded-Uri,X-Forwarded-For,Cookie"

  # === CONFIGURATION DU SERVICE ===
  -l "traefik.http.services.postgrest.loadbalancer.server.port=3000"             # Port du service PostgREST
)

# Lancement du conteneur PostgREST
echo "Demarrage de PostgREST (auth deja faite sur /)"
echo "Configuration :"
echo "  - API accessible sur : https://localhost/api/"
echo "  - Authentification via OAuth2-Proxy middleware"
echo "  - Base de donnees : app_db sur PostgreSQL"
sudo docker run "${PGRST_OPTS[@]}" postgrest/postgrest

echo "PostgREST demarre avec succes !"
echo "Test de l'API : curl -k https://localhost/api/ (apres authentification)"

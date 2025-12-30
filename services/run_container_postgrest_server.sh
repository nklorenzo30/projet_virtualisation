#!/bin/bash
# Nettoyage
sudo docker rm -f postgrest_server 2>/dev/nul
POSTGREST_ARGS=(
  --name postgrest_server
  --network mynet
 
  # --- CONFIGURATION POSTGREST ---
  -e PGRST_DB_URI="postgres://admin:admin123@db:5432/app_db"
  -e PGRST_DB_SCHEMAS="public"
  -e PGRST_DB_ANON_ROLE="anon"
  # Le serveur écoute sur toutes les interfaces internes du conteneur
  -e PGRST_SERVER_HOST="0.0.0.0" 
  -e PGRST_SERVER_PORT="3000"
  -e PGRST_JWT_SECRET="-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3WGE3fOntltprT8IrYG3q376Q6PBrUzfsZ81P3Otw27yJzYb0diQ5ReZm9NCMKnrgBRxPtBazq34K5xd0InGrSZXvC3C7RkAOE46TZIL8WI35O4Fhrn3X1bHz0q+yynaMTL2COUktlm+j+AOkzjKAO5Xb1r1OxGGJ0V/ZW1BwuPlThH4GcqXnOdBRCCeeh7ybbUsRNK08lxn3+rh7hOwRjZAuy+skWtJUuD4DSS25900K+aVEb8mI/QPS+4ek2Co88K3cpHKMbqODGHHkxUPF3gmoC2QWajEzxkhiGCMSnVmMWvBmjCUe6dHjguBS9jJ8ye08MRGnNzgB97Vat6yuQIDAQAB\n-----END PUBLIC KEY-----" 
  -e PGRST_JWT_AUD="API" 
  
  # --- LABELS TRAEFIK ---
  -l "traefik.enable=true"
  
  # 1. ROUTAGE
  # On intercepte tout ce qui commence par /api
  -l "traefik.http.routers.postgrest.rule=PathPrefix(\`/api\`)"
  
  # 2. ENTRYPOINT (HTTPS)
  -l "traefik.http.routers.postgrest.entrypoints=https"
  
  # 3. MIDDLEWARE (Nettoyage d'URL)
  # C'est CRUCIAL ici. Si on envoie /api/users à PostgREST, il va chercher
  # une table api, ce qui échouera.
  # On applique le middleware strip-api défini juste en dessous.
  -l "traefik.http.routers.postgrest.middlewares=strip-api"
  
  # Définition du middleware : on enlève /api avant d'envoyer la requête au container
  -l "traefik.http.middlewares.strip-api.stripprefix.prefixes=/api"
  
  # 4. SERVICE
  # Port interne de PostgREST
  -l "traefik.http.services.postgrest.loadbalancer.server.port=3000"
  # --- IMAGE ---
  postgrest/postgrest

)

sudo docker run -d "${POSTGREST_ARGS[@]}"

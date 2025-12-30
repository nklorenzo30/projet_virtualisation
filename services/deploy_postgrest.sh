#!/bin/bash

# --- 1. Saisie Utilisateur ---
while true; do
  read -p "Combien d'instances PostgREST souhaitez-vous déployer (minimum 1) ? " REPLICAS
  
  # Validation : Vérifie si c'est un nombre entier et supérieur ou égal à 1
  if [[ "$REPLICAS" =~ ^[0-9]+$ ]] && [ "$REPLICAS" -ge 1 ]; then
    break
  else
    echo "Saisie invalide. Veuillez entrer un nombre entier supérieur ou égal à 1."
  fi
done

echo "Déploiement de $REPLICAS répliques PostgREST sur le réseau mynet..."

# --- 2. Boucle de Déploiement ---
for i in $(seq 1 $REPLICAS); do
  
  CONTAINER_NAME="postgrest-server-$i"
  # Le nom dynamique est utilisé pour les labels Traefik
  DYNAMIC_NAME="postgrest-$i"
  
  # Nettoyage de l'ancienne instance
  sudo docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1
  
  # --- DÉFINITION DU TABLEAU D'ARGUMENTS ---
  POSTGREST_ARGS=(
    --name "$CONTAINER_NAME"
    --network mynet
    
    # --- CONFIGURATION POSTGREST ---
    -e PGRST_DB_URI="postgres://admin:admin123@db:5432/app_db"
    -e PGRST_DB_SCHEMAS="public"
    -e PGRST_DB_ANON_ROLE="anon"
    -e PGRST_SERVER_HOST="0.0.0.0"
    -e PGRST_SERVER_PORT="3000"
    
    # --- LABELS TRAEFIK (NOMS DYNAMIQUES) ---
    -l "traefik.enable=true"
    
    # 1. ROUTAGE (Le nom du routeur est unique: postgrest-1, postgrest-2, etc.)
    # La règle PathPrefix reste identique pour toutes les instances.
    -l "traefik.http.routers.$DYNAMIC_NAME.rule=PathPrefix(\`/api\`)"
    -l "traefik.http.routers.$DYNAMIC_NAME.entrypoints=https"
    
    # 2. MIDDLEWARE (Le nom du middleware doit aussi être unique pour être bien lié)
    -l "traefik.http.routers.$DYNAMIC_NAME.middlewares=strip-api-$i"
    -l "traefik.http.middlewares.strip-api-$i.stripprefix.prefixes=/api"
    
    # 3. SERVICE (Le nom du service est unique: postgrest-1, postgrest-2, etc.)
    -l "traefik.http.services.$DYNAMIC_NAME.loadbalancer.server.port=3000"
    
    # --- IMAGE ---
    postgrest/postgrest
  )
  
  # 3. Lancement du conteneur
  sudo docker run -d "${POSTGREST_ARGS[@]}"
  
  echo "  Instance $i/$REPLICAS ($CONTAINER_NAME) déployée."
done

echo "Déploiement terminé. Traefik équilibre la charge sur /api."

#!/bin/bash
#
# Script d'obtention de token d'acces Keycloak
# ============================================
#
# Ce script utilise le flux "Resource Owner Password Credentials" pour
# obtenir un token d'acces OAuth2/OIDC depuis Keycloak. Utile pour tester
# l'API PostgREST ou debugger l'authentification.
#
# Fonctionnalites :
# - Authentification directe avec username/password
# - Extraction du token d'acces JWT
# - Utilisation du client 'traefik-client' configure
#
# Usage : ./get_accestoken.sh
# Le token sera affiche en sortie pour utilisation dans d'autres requetes
#
# Exemple d'utilisation du token :
# TOKEN=$(./get_accestoken.sh | grep "Token:" | cut -d' ' -f2)
# curl -H "Authorization: Bearer $TOKEN" https://localhost/api/
#

# === CONFIGURATION D'AUTHENTIFICATION ===
# Parametres de connexion Keycloak et utilisateur de test
REALM="myrealm"                                    # Nom du realm Keycloak
CLIENT_ID="traefik-client"                         # ID du client OAuth2
CLIENT_SECRET="E0EfyreeUDBlfb9pKO3S3qElan8b5adi"   # Secret du client OAuth2
USERNAME="user1"                                   # Nom d'utilisateur de test
PASSWORD="1234"                                    # Mot de passe de test
KEYCLOAK_URL="https://localhost/auth"              # URL de base de Keycloak

echo "Demande de token d'acces pour l'utilisateur: $USERNAME"

# === REQUETE DE TOKEN ===
# Utilisation du flux "password" (Resource Owner Password Credentials Grant)
echo "Connexion a Keycloak..."
TOKEN_JSON=$(curl -k -v -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -d "grant_type=password" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD")

# === EXTRACTION DU TOKEN ===
# Utilisation de jq pour extraire le token d'acces de la reponse JSON
ACCESS_TOKEN=$(echo "$TOKEN_JSON" | jq -r '.access_token')

# === AFFICHAGE DU RESULTAT ===
if [ "$ACCESS_TOKEN" != "null" ] && [ -n "$ACCESS_TOKEN" ]; then
    echo ""
    echo "=== TOKEN D'ACCES OBTENU ==="
    echo "Token: $ACCESS_TOKEN"
    echo ""
    echo "Utilisation :"
    echo "curl -k -H \"Authorization: Bearer $ACCESS_TOKEN\" https://localhost/api/"
else
    echo ""
    echo "=== ERREUR ==="
    echo "Impossible d'obtenir le token d'acces."
    echo "Reponse Keycloak: $TOKEN_JSON"
    echo ""
    echo "Verifications :"
    echo "- Keycloak est-il accessible ?"
    echo "- L'utilisateur $USERNAME existe-t-il ?"
    echo "- Le client $CLIENT_ID est-il configure correctement ?"
fi


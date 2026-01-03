# Architecture Web Securisee avec OAuth2-Proxy et PostgREST

## Vue d'ensemble

Cette architecture fournit une solution complete d'authentification et d'API securisee utilisant :

- **Traefik** comme reverse proxy principal
- **OAuth2-Proxy** pour l'authentification centralisee via Keycloak
- **Nginx** pour l'interface web
- **PostgREST** pour l'API REST securisee
- **Keycloak** comme serveur d'identite
- **PostgreSQL** comme base de donnees

## Architecture

![Architecture Diagram](./architecture_micro-service.png)

**Flux principal :**

```
Utilisateur -> Traefik -> OAuth2-Proxy -> {Nginx (web), PostgREST (API)}
                           |
                      Keycloak (Auth)
                           |
                     PostgreSQL (DB)
```

## Flux d'authentification

1. **Interface Web** : `https://localhost/`

   - Traefik -> OAuth2-Proxy -> Nginx
   - Authentification obligatoire via Keycloak

2. **API PostgREST** : `https://localhost/api/`
   - Traefik -> OAuth2-Proxy (middleware) -> PostgREST
   - Authentification partagee avec l'interface web

## Prerequis

- Docker et Docker Network `mynet`
- Keycloak configure avec le realm `myrealm` et le client `traefik-client`
- PostgreSQL avec la base de donnees `app_db`
- Traefik en cours d'execution

## Scripts disponibles

### Scripts de conteneurs individuels

- `run_container_oauth2-proxy.sh` - OAuth2-Proxy principal
- `run_container_web.sh` - Conteneur web Nginx
- `run_container_postgrest_server.sh` - API PostgREST securisee

### Script de deploiement

- `deploy_simple.sh` - Deploiement complet de l'architecture

## Configuration

### OAuth2-Proxy

**Variables d'environnement principales :**

```bash
OAUTH2_PROXY_PROVIDER="keycloak-oidc"
OAUTH2_PROXY_CLIENT_ID="traefik-client"
OAUTH2_PROXY_CLIENT_SECRET="XCZdmj39fKdpFag9kTV6GZU1HmB8ezhv"
OAUTH2_PROXY_OIDC_ISSUER_URL="http://keycloak:8080/auth/realms/myrealm"
OAUTH2_PROXY_UPSTREAMS="http://web1:80"
```

**Labels Traefik :**

- Router principal : `Host(localhost)` (priorite 1)
- Router auth : `Host(localhost) && PathPrefix(/oauth2)` (priorite 10)

### PostgREST

**Configuration base de donnees :**

```bash
PGRST_DB_URI="postgres://admin:admin123@db:5432/app_db"
PGRST_DB_SCHEMA="public"
PGRST_DB_ANON_ROLE="anon"
```

**Middleware d'authentification :**

- Utilise le middleware `web-auth@docker`
- Forward auth vers `http://oauth2-proxy:4180/oauth2/auth`
- Transmission des cookies pour l'authentification

## Deploiement

### Deploiement rapide

```bash
./deploy_simple.sh
```

### Deploiement manuel

1. **Demarrer OAuth2-Proxy :**

   ```bash
   ./run_container_oauth2-proxy.sh
   ```

2. **Demarrer le conteneur web :**

   ```bash
   ./run_container_web.sh web1
   ```

3. **Demarrer PostgREST :**
   ```bash
   ./run_container_postgrest_server.sh
   ```

## Acces aux services

- **Interface Web** : https://localhost/
- **API PostgREST** : https://localhost/api/
- **Endpoints OAuth2** : https://localhost/oauth2/
- **Dashboard Traefik** : http://localhost:8080/

## Securite

### Authentification

- **Single Sign-On (SSO)** via Keycloak
- **Cookies securises** avec domaine `localhost`
- **Transmission de tokens** pour l'API
- **Validation OIDC** avec verification des certificats

### Configuration securisee

- **Secret de cookie fixe** partage entre les instances
- **Headers d'authentification** transmis a PostgREST
- **Validation des audiences** avec `web_user`
- **Protection CSRF** integree

## Depannage

### Problèmes courants

1. **404 après authentification**

   - Vérifier que `web1` est accessible depuis OAuth2-Proxy
   - Contrôler les logs : `sudo docker logs oauth2-proxy`

2. **API Unauthorized**

   - S'assurer d'être authentifié sur l'interface web d'abord
   - Vérifier la transmission des cookies dans le middleware

3. **Conflits de services Traefik**
   - Vérifier les logs Traefik : `sudo docker logs traefik`
   - S'assurer qu'il n'y a pas de services dupliqués

### Commandes de diagnostic

```bash
# Vérifier l'état des conteneurs
sudo docker ps

# Logs OAuth2-Proxy
sudo docker logs oauth2-proxy --tail=20

# Logs PostgREST
sudo docker logs postgrest --tail=20

# Logs Traefik
sudo docker logs traefik --tail=20

# Tester l'authentification
curl -k -I https://localhost/

# Tester l'API (nécessite une session authentifiée)
curl -k https://localhost/api/ -H "Accept: application/json"
```

## Structure des fichiers

```
.
├── README.md                           # Cette documentation
├── deploy_simple.sh                    # Script de déploiement complet
├── run_container_oauth2-proxy.sh       # OAuth2-Proxy
├── run_container_web.sh               # Conteneur web Nginx
├── run_container_postgrest_server.sh  # API PostgREST
└── [autres scripts de services...]
```

## Évolutions possibles

- **Load balancing** : Ajouter plusieurs instances web
- **Cache Redis** : Pour les sessions OAuth2-Proxy
- **Monitoring** : Intégration Prometheus/Grafana
- **SSL/TLS** : Certificats Let's Encrypt via Traefik
- **Base de données** : Réplication PostgreSQL

## Support

Pour toute question ou problème :

1. Vérifier les logs des conteneurs
2. Contrôler la configuration Keycloak
3. Valider la connectivité réseau Docker
4. Tester l'accès aux services individuellement

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

### Scripts de monitoring

- `run_container_prometheus.sh` - Serveur de metriques Prometheus (avec regles d'alertes)
- `run_container_cadvisor.sh` - Collecteur de metriques conteneurs
- `run_container_grafana.sh` - Interface de visualisation Grafana
- `run_container_alertmanager.sh` - Gestionnaire d'alertes et notifications

### Scripts d'infrastructure

- `run_container_traefik.sh` - Reverse proxy Traefik
- `run_container_keycloak.sh` - Serveur d'identite Keycloak
- `run_container_db.sh` - Base de donnees PostgreSQL

### Scripts de deploiement et monitoring

- `deploy_monitoring_stack.sh` - Deploiement complet de toute l'architecture
- `monitor_stack.sh` - Monitoring global de l'etat de la stack
- `test_alertmanager.sh` - Test et validation d'Alertmanager

### Utilitaires

- `get_accestoken.sh` - Obtention de tokens d'acces OAuth2
- `test_api.sh` - Tests automatises de l'API

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

## Evolutions possibles

- **Load balancing** : Ajouter plusieurs instances web
- **Cache Redis** : Pour les sessions OAuth2-Proxy
- **Monitoring** : Integration Prometheus/Grafana
- **SSL/TLS** : Certificats Let's Encrypt via Traefik
- **Base de donnees** : Replication PostgreSQL

## Monitoring et Observabilite

Cette architecture inclut une stack de monitoring complete avec **Prometheus**, **cAdvisor** et **Grafana** pour une surveillance avancee de tous les services.

### Stack de monitoring deployee

#### Prometheus - Collecte de metriques
- **Script** : `run_container_prometheus.sh`
- **Port** : 9091 (interface web)
- **Configuration** : `./prometheus/prometheus.yml`
- **Fonctionnalites** :
  - Collecte des metriques cAdvisor toutes les 5 secondes
  - Integration avec Alertmanager
  - Stockage persistant des donnees

#### cAdvisor - Metriques conteneurs
- **Script** : `run_container_cadvisor.sh`
- **Port** : 5000 (interface web)
- **Fonctionnalites** :
  - Surveillance CPU, memoire, reseau, I/O de tous les conteneurs
  - Metriques en temps reel
  - Integration native avec Prometheus

#### Grafana - Visualisation
- **Script** : `run_container_grafana.sh`
- **Port** : 3000 (interface web)
- **Acces** : http://localhost:3000
- **Fonctionnalites** :
  - Dashboards personnalisables
  - Alertes visuelles
  - Stockage persistant des configurations

#### Alertmanager - Gestion des alertes
- **Script** : `run_container_alertmanager.sh`
- **Port** : 9093 (interface web)
- **Configuration** : `./alertmanager/config.yml`
- **Fonctionnalites** :
  - Routage intelligent des alertes par severite
  - Notifications email configurees avec Gmail
  - Groupement et deduplication des alertes
  - Integration complete avec Prometheus

### Deploiement de la stack monitoring

#### Deploiement complet automatise
```bash
# Deploiement de toute l'architecture (infrastructure + monitoring)
./deploy_monitoring_stack.sh
```

#### Deploiement manuel de la stack monitoring
```bash
# 1. Demarrer cAdvisor
./run_container_cadvisor.sh

# 2. Demarrer Prometheus (avec regles d'alertes)
./run_container_prometheus.sh

# 3. Demarrer Alertmanager
./run_container_alertmanager.sh

# 4. Demarrer Grafana
./run_container_grafana.sh
```

### Monitoring et verification

#### Script de monitoring global
```bash
# Verification complete de la stack
./monitor_stack.sh
```

#### Test des alertes
```bash
# Test et validation d'Alertmanager
./test_alertmanager.sh
```

### Acces aux interfaces de monitoring

| Service | URL | Description |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | Dashboards et visualisations |
| **Prometheus** | http://localhost:9091 | Interface de requetes et metriques |
| **Alertmanager** | http://localhost:9093 | Gestion des alertes et notifications |
| **cAdvisor** | http://localhost:5000 | Metriques conteneurs en temps reel |
| **Traefik** | http://localhost:8080 | Dashboard reverse proxy |

### Configuration Prometheus

Le fichier `prometheus/prometheus.yml` configure :

```yaml
scrape_configs:
- job_name: cadvisor
  scrape_interval: 5s        # Collecte toutes les 5 secondes
  static_configs:
  - targets:
    - cadvisor:8080          # Endpoint cAdvisor

# Integration Alertmanager
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093  # Service d'alertes
```

### Metriques disponibles

#### Via cAdvisor (conteneurs)
- **CPU** : Utilisation par conteneur
- **Memoire** : RAM utilisee/disponible
- **Reseau** : Trafic entrant/sortant
- **Stockage** : I/O disque par conteneur
- **Processus** : Nombre de processus actifs

#### Via Traefik (reverse proxy)
- **Requetes HTTP** : Nombre, codes de reponse
- **Latence** : Temps de reponse par service
- **Backends** : Etat de sante des services
- **Certificats** : Expiration SSL/TLS

### Dashboards Grafana recommandes

#### Dashboard Infrastructure
```bash
# Metriques a surveiller :
- container_cpu_usage_seconds_total
- container_memory_usage_bytes
- container_network_receive_bytes_total
- container_network_transmit_bytes_total
```

#### Dashboard Application
```bash
# Metriques specifiques aux services :
- traefik_http_requests_total
- traefik_http_request_duration_seconds
- oauth2_proxy_requests_total (si active)
```

### Alertes et seuils recommandes

#### Alertes critiques
- **CPU > 80%** pendant 5 minutes
- **Memoire > 90%** pendant 2 minutes
- **Service indisponible** pendant 1 minute
- **Erreurs HTTP 5xx > 10%** pendant 5 minutes

#### Configuration d'alertes Grafana
1. Connecter Prometheus comme source de donnees
2. Creer des alertes sur les metriques critiques
3. Configurer les notifications (email, Slack, etc.)

### Commandes de monitoring utiles

#### Verification de l'etat des services monitoring
```bash
# Verifier que tous les services monitoring sont actifs
docker ps --filter "name=prometheus" --filter "name=cadvisor" --filter "name=grafana"

# Tester la connectivite Prometheus -> cAdvisor
curl -s http://localhost:9091/api/v1/targets | jq '.data.activeTargets[].health'

# Verifier les metriques cAdvisor
curl -s http://localhost:5000/metrics | grep container_cpu_usage_seconds_total
```

#### Requetes Prometheus utiles
```bash
# Top 5 conteneurs par CPU
topk(5, rate(container_cpu_usage_seconds_total[5m]))

# Utilisation memoire par conteneur
container_memory_usage_bytes / container_spec_memory_limit_bytes * 100

# Trafic reseau par conteneur
rate(container_network_receive_bytes_total[5m])
```

### Troubleshooting monitoring

#### Problemes courants
1. **Prometheus ne collecte pas les metriques**
   ```bash
   # Verifier la configuration
   docker logs prometheus
   curl http://localhost:9091/api/v1/targets
   ```

2. **cAdvisor n'affiche pas tous les conteneurs**
   ```bash
   # Verifier les permissions et montages
   docker logs cadvisor
   ```

3. **Grafana ne se connecte pas a Prometheus**
   ```bash
   # Verifier la connectivite reseau
   docker exec grafana ping prometheus
   ```

## Support

Pour toute question ou problème :

1. Vérifier les logs des conteneurs
2. Contrôler la configuration Keycloak
3. Valider la connectivité réseau Docker
4. Tester l'accès aux services individuellement

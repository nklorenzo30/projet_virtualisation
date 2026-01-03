# Configuration des Alertes basées sur le Dashboard

## 📊 Correspondance Dashboard ↔ Règles d'Alertes

### 1. **Nombre de conteneurs actifs**
**Métrique Dashboard:** `count(container_start_time_seconds{name!=""})`
**Règles d'Alertes:**
```yaml
- alert: LowActiveContainers
  expr: count(container_start_time_seconds{name!=""}) < 8
  for: 2m
  severity: warning

- alert: ContainerCountAnomaly  
  expr: abs(count(container_start_time_seconds{name!=""}) - 10) > 2
  for: 2m
  severity: warning
```

### 2. **UPTIME des conteneurs**
**Métrique Dashboard:** `max by (name) ((time() - container_start_time_seconds{name!=""}))`
**Règles d'Alertes:**
```yaml
- alert: ContainerRecentRestart
  expr: (time() - container_start_time_seconds{name!=""}) < 300
  for: 1m
  severity: info

- alert: LowAverageUptime
  expr: avg(time() - container_start_time_seconds{name!=""}) < 3600
  for: 5m
  severity: info
```

### 3. **CPU (Bar Gauge)**
**Métrique Dashboard:** `100 * sum by (name) (rate(container_cpu_usage_seconds_total{name!=""}[5m]))`
**Règles d'Alertes:**
```yaml
- alert: ContainerHighCPU
  expr: 100 * sum by (name) (rate(container_cpu_usage_seconds_total{name!=""}[5m])) > 80
  for: 3m
  severity: warning

- alert: ContainerCriticalCPU
  expr: 100 * sum by (name) (rate(container_cpu_usage_seconds_total{name!=""}[5m])) > 95
  for: 1m
  severity: critical
```

### 4. **Débit entrant (RX)**
**Métrique Dashboard:** `sum by (name) (rate(container_network_receive_bytes_total{name!=""}[5m])) * 8 / 1024 / 1024`
**Règles d'Alertes:**
```yaml
- alert: ContainerHighNetworkRX
  expr: sum by (name) (rate(container_network_receive_bytes_total{name!=""}[5m])) * 8 / 1024 / 1024 > 100
  for: 3m
  severity: warning
```

### 5. **Mémoire (Pie Chart)**
**Métrique Dashboard:** `sum by (name) (container_memory_working_set_bytes{name!=""}) / 1073741824`
**Règles d'Alertes:**
```yaml
- alert: ContainerHighMemory
  expr: sum by (name) (container_memory_working_set_bytes{name!=""}) / 1073741824 > 2
  for: 5m
  severity: warning

- alert: HighTotalMemoryUsage
  expr: sum(container_memory_working_set_bytes{name!=""}) / 1073741824 > 8
  for: 3m
  severity: warning
```

### 6. **Débit sortant (TX)**
**Métrique Dashboard:** `sum by (name) (rate(container_network_transmit_bytes_total{name!=""}[5m]) * 8 / 1024 / 1024)`
**Règles d'Alertes:**
```yaml
- alert: ContainerHighNetworkTX
  expr: sum by (name) (rate(container_network_transmit_bytes_total{name!=""}[5m]) * 8 / 1024 / 1024) > 100
  for: 3m
  severity: warning
```

### 7. **I/O Disque (Lecture)**
**Métrique Dashboard:** `sum by (name) (rate(container_fs_reads_bytes_total{name!=""}[5m]))`
**Règles d'Alertes:**
```yaml
- alert: ContainerHighDiskRead
  expr: sum by (name) (rate(container_fs_reads_bytes_total{name!=""}[5m])) > 104857600
  for: 5m
  severity: warning
```

### 8. **I/O Disque (Écriture)**
**Métrique Dashboard:** `sum by (name) (rate(container_fs_writes_bytes_total{name!=""}[5m]))`
**Règles d'Alertes:**
```yaml
- alert: ContainerHighDiskWrite
  expr: sum by (name) (rate(container_fs_writes_bytes_total{name!=""}[5m])) > 104857600
  for: 5m
  severity: warning
```

## 🎯 Seuils configurés

| Métrique | Seuil Warning | Seuil Critical | Durée |
|----------|---------------|----------------|-------|
| Conteneurs actifs | < 8 | < 6 | 2m |
| CPU par conteneur | > 80% | > 95% | 3m/1m |
| Mémoire par conteneur | > 2GB | > 4GB | 5m |
| Réseau RX/TX | > 100Mbps | > 500Mbps | 3m |
| I/O Disque | > 100MB/s | > 500MB/s | 5m |
| Uptime | < 5min | < 1min | 1m |

## 🔧 Personnalisation des seuils

Pour ajuster les seuils selon vos besoins, modifiez le fichier `prometheus/alert_rules.yml` :

```bash
# Éditer les règles
sudo nano prometheus/alert_rules.yml

# Redémarrer Prometheus pour appliquer
sudo docker restart prometheus
```

## 📧 Notifications configurées

Les alertes sont envoyées via :
- **Email** : Notifications Gmail configurées
- **Webhook** : API disponible pour intégrations
- **Interface Web** : http://localhost:9093

## 🧪 Test des alertes

```bash
# Tester toutes les alertes
sudo ./test_alertmanager.sh

# Vérifier les règles chargées
curl http://localhost:9091/api/v1/rules

# Voir les alertes actives
curl http://localhost:9093/api/v1/alerts
```
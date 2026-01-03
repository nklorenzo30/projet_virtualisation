# Configuration Alertmanager

## Vue d'ensemble

Alertmanager gère les alertes envoyées par Prometheus et les route vers les canaux de notification appropriés. Cette configuration inclut :

- **Routage intelligent** des alertes par sévérité
- **Notifications email** configurées avec Gmail
- **Groupement** et déduplication des alertes
- **Inhibition** pour éviter le spam d'alertes

## Structure de la configuration

### Routage des alertes

```yaml
route:
  group_by: ['alertname', 'instance']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default-notifications'
```

### Récepteurs configurés

| Récepteur | Usage | Délai de répétition |
|-----------|-------|-------------------|
| `default-notifications` | Alertes générales | 4h |
| `critical-notifications` | Alertes critiques | 30m |
| `infrastructure-notifications` | Problèmes infra | 4h |
| `auth-notifications` | Problèmes OAuth2-Proxy | 4h |
| `api-notifications` | Problèmes PostgREST | 4h |

## Types d'alertes configurées

### Alertes critiques (30m de répétition)
- Services indisponibles
- Utilisation mémoire > 90%
- Conteneurs arrêtés

### Alertes d'avertissement (4h de répétition)
- Utilisation CPU > 80%
- Latence API élevée
- Taux d'erreur > 5%

## Configuration email

### Paramètres SMTP
```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'iaconnection237@gmail.com'
  smtp_auth_username: 'iaconnection237@gmail.com'
  smtp_require_tls: true
```

### Format des notifications

Les emails incluent :
- **Sujet** avec niveau de sévérité
- **Description** détaillée de l'alerte
- **Valeurs** des métriques
- **Liens** vers Grafana et Prometheus
- **Actions recommandées** pour résoudre

## Règles d'inhibition

Pour éviter le spam d'alertes :

1. **Service Down** inhibe les alertes de performance
2. **Container Down** inhibe les alertes de métriques du conteneur

## Commandes utiles

### Vérifier le statut
```bash
curl http://localhost:9093/api/v1/status
```

### Voir les alertes actives
```bash
curl http://localhost:9093/api/v1/alerts | jq
```

### Tester la configuration
```bash
./test_alertmanager.sh
```

### Envoyer une alerte de test
```bash
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {"alertname": "TestAlert", "severity": "warning"},
    "annotations": {"summary": "Test alert"}
  }]'
```

### Créer un silence
```bash
curl -X POST http://localhost:9093/api/v1/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [{"name": "alertname", "value": "TestAlert"}],
    "startsAt": "2024-01-01T00:00:00Z",
    "endsAt": "2024-01-01T01:00:00Z",
    "comment": "Maintenance programmée"
  }'
```

## Dépannage

### Problèmes courants

1. **Emails non reçus**
   - Vérifier les paramètres SMTP
   - Contrôler les logs : `docker logs alertmanager`
   - Tester avec `./test_alertmanager.sh`

2. **Alertes non routées**
   - Vérifier la syntaxe YAML
   - Contrôler les labels des alertes
   - Valider avec l'API status

3. **Trop d'alertes**
   - Ajuster les seuils dans `alert_rules.yml`
   - Configurer des silences temporaires
   - Modifier les intervalles de répétition

### Logs utiles
```bash
# Logs Alertmanager
docker logs alertmanager --tail=50

# Vérifier la connectivité Prometheus
curl http://localhost:9091/api/v1/alertmanagers

# État des règles d'alertes
curl http://localhost:9091/api/v1/rules
```

## Évolutions possibles

### Canaux de notification supplémentaires
- **Slack** : Notifications dans des channels
- **Discord** : Webhooks pour les équipes
- **PagerDuty** : Escalade automatique
- **SMS** : Alertes critiques urgentes

### Améliorations du routage
- **Horaires** : Pas d'alertes la nuit
- **Équipes** : Routage par responsable
- **Géolocalisation** : Alertes par région

### Templates personnalisés
- **HTML enrichi** avec graphiques
- **Dashboards** intégrés dans les emails
- **Actions** directes depuis les notifications
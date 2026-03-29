# Étape 10 — Auto-déploiement DEV/PROD

> **Branche :** `step-10/auto-deploy-dev-prod`
> **CKA Section :** Cluster Maintenance (11% de l'examen)

---

## 🎯 Objectif CKA

Maîtriser la maintenance et le déploiement en production :
- **Rolling Updates** : mise à jour sans downtime
- **Rollbacks** : retour en arrière en cas de problème
- **Draining Nodes** : maintenance des noeuds
- **Backup etcd** : sauvegarde de la base de données du cluster
- **Cluster Upgrade** : mise à jour de Kubernetes

---

## 📋 Tâches de cette étape

- [ ] Créer le workflow **CD DEV** (déploiement auto sur branche `develop`)
- [ ] Créer le workflow **CD PROD** (déploiement auto sur branche `main`)
- [ ] Implémenter la stratégie de **Rolling Update**
- [ ] Tester le **Rollback automatique** en cas d'échec
- [ ] Configurer les **environment GitHub** avec protection rules
- [ ] Documenter la procédure de **backup etcd**

---

## 📐 Stratégie de déploiement

```
┌─────────────────────────────────────────────────────────────┐
│                    Deployment Strategy                       │
│                                                             │
│  RollingUpdate (défaut)                                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Old v1  Old v1  Old v1                                 │ │
│  │    ↓       ↓       ↓                                   │ │
│  │  New v2  New v2  New v2   (maxSurge: 1, maxUnavail: 0)  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                             │
│  Blue/Green (avancé)                                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Blue (v1): 3 pods    ──────────────── Traffic: 100%   │ │
│  │  Green (v2): 3 pods   ──────────────── Traffic: 0%     │ │
│  │  Test Green OK?  →  Switch traffic to Green            │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📐 Configuration RollingUpdate

```yaml
# Dans le Deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Pods supplémentaires durant la MAJ
      maxUnavailable: 0  # Pods indisponibles acceptés (0 = pas de downtime)
  minReadySeconds: 5     # Attendre 5s avant de considérer le pod "ready"
```

---

## 📐 Workflow CD DEV (extrait)

```yaml
# .github/workflows/cd-dev.yml
name: CD - Deploy to DEV

on:
  push:
    branches: [develop]

jobs:
  deploy-dev:
    runs-on: ubuntu-latest
    environment: development
    steps:
      - name: Deploy to DEV
        run: |
          # Mise à jour de l'image dans le déploiement
          kubectl set image deployment/village-frontend \
            frontend=${{ env.REGISTRY }}/${{ env.IMAGE_FRONTEND }}:dev-${{ github.sha }} \
            -n village-dev
          
          # Attendre que le déploiement soit terminé
          kubectl rollout status deployment/village-frontend -n village-dev --timeout=300s
          
          # En cas d'échec, rollback automatique
          if [ $? -ne 0 ]; then
            kubectl rollout undo deployment/village-frontend -n village-dev
            exit 1
          fi
```

---

## 🔧 Commandes kubectl (Cluster Maintenance)

```bash
# Voir l'historique des déploiements
kubectl rollout history deployment/village-frontend -n village-dev

# Voir les détails d'une révision spécifique
kubectl rollout history deployment/village-frontend -n village-dev --revision=2

# Rollback vers la révision précédente
kubectl rollout undo deployment/village-frontend -n village-dev

# Rollback vers une révision spécifique
kubectl rollout undo deployment/village-frontend --to-revision=1 -n village-dev

# Mettre un noeud en maintenance (drain)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Remettre le noeud en service
kubectl uncordon <node-name>

# Backup etcd (CKA important !)
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key

# Vérifier le backup etcd
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db

# Mettre à jour kubectl
sudo apt-get update && sudo apt-get install -y kubectl=1.28.0-00
```

---

## 🌍 Environnements GitHub

| Environnement | Branche | Protection | Secrets |
|---------------|---------|------------|---------|
| `development` | `develop` | Aucune | `KUBE_CONFIG_DEV` |
| `production` | `main` | Required reviewers | `KUBE_CONFIG_PROD` |

### Configurer les environments GitHub
```
GitHub → Settings → Environments → New environment
→ "production" → Add required reviewers → Add secrets
```

---

## ✅ Critères de validation

- [ ] Workflow CD DEV déclenché sur push vers `develop`
- [ ] Workflow CD PROD déclenché sur push vers `main` (avec approbation)
- [ ] Rolling Update sans downtime (`maxUnavailable: 0`)
- [ ] Rollback automatique en cas d'échec du déploiement
- [ ] Environments GitHub configurés avec les bonnes protections
- [ ] `kubectl rollout history` montrant l'historique des déploiements

---

## 🔗 Ressources

- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [Cluster Maintenance](https://kubernetes.io/docs/tasks/administer-cluster/)
- [etcd Backup](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)
- [KodeKloud CKA — Cluster Maintenance](https://learn.kodekloud.com/user/courses/cka-certification-course-certified-kubernetes-administrator)

---

*Étape précédente → [Étape 09 — GitHub Actions](step-09-github-actions.md)*
*🎉 Félicitations ! Vous avez complété toutes les étapes du projet !*

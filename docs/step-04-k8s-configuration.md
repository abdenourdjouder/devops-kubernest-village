# Étape 04 — Configuration

> **Branche :** `step-04/k8s-configuration`
> **CKA Section :** Configuration (18% de l'examen)

---

## 🎯 Objectif CKA

Maîtriser la configuration des applications dans Kubernetes :
- **ConfigMap** : stocker la configuration non-sensible
- **Secret** : stocker les données sensibles (encodées en base64)
- **Resource Requests & Limits** : garantir et limiter les ressources CPU/mémoire
- **Environment Variables** : injecter la configuration dans les conteneurs
- **Namespaces** : isolation et quotas de ressources

---

## 📋 Tâches de cette étape

- [ ] Créer des **ConfigMaps** pour les variables d'environnement (URLs API, profils)
- [ ] Créer des **Secrets** pour les mots de passe et clés API
- [ ] Ajouter des **Resource Requests et Limits** aux conteneurs
- [ ] Injecter les variables depuis ConfigMap et Secret dans les pods
- [ ] Créer un **ResourceQuota** par namespace

---

## 📐 Manifestes Kubernetes (Configuration)

### ConfigMap Frontend
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: village-dev
data:
  API_URL: "http://village-backend-svc:8080"
  ENVIRONMENT: "dev"
  APP_TITLE: "Village App - DEV"
```

### ConfigMap Backend
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: village-dev
data:
  SPRING_PROFILES_ACTIVE: "dev"
  SERVER_PORT: "8080"
  DB_HOST: "postgres-svc"
  DB_PORT: "5432"
  DB_NAME: "villagedb"
```

### Secret (base64 encodé)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secret
  namespace: village-dev
type: Opaque
data:
  # echo -n "password" | base64
  DB_PASSWORD: cGFzc3dvcmQ=
  # echo -n "mySecretKey" | base64
  JWT_SECRET: bXlTZWNyZXRLZXk=
```

### ResourceQuota
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: village-quota
  namespace: village-dev
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "20"
```

---

## 🔧 Commandes kubectl (Configuration)

```bash
# Appliquer les ConfigMaps et Secrets
kubectl apply -f k8s/frontend/configmap.yaml
kubectl apply -f k8s/backend/configmap.yaml
kubectl apply -f k8s/backend/secret.yaml

# Lister les ConfigMaps
kubectl get configmaps -n village-dev

# Voir le contenu d'un ConfigMap
kubectl describe configmap frontend-config -n village-dev
kubectl get configmap frontend-config -n village-dev -o yaml

# Lister les Secrets
kubectl get secrets -n village-dev

# Créer un secret manuellement
kubectl create secret generic my-secret \
  --from-literal=password=mypassword \
  -n village-dev

# Encoder/décoder base64
echo -n "mypassword" | base64
echo -n "bXlwYXNzd29yZA==" | base64 -d

# Vérifier les resource limits d'un pod
kubectl describe pod <pod-name> -n village-dev | grep -A5 "Limits\|Requests"

# Voir les quotas du namespace
kubectl describe resourcequota -n village-dev
```

---

## ✅ Critères de validation

- [ ] ConfigMaps créés pour frontend et backend
- [ ] Secrets créés pour les données sensibles
- [ ] Resource Requests et Limits définis sur tous les conteneurs
- [ ] Variables d'environnement correctement injectées dans les pods
- [ ] ResourceQuota appliqué sur le namespace dev

---

## 🔗 Ressources

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [KodeKloud CKA — Configuration](https://learn.kodekloud.com/user/courses/cka-certification-course-certified-kubernetes-administrator)

---

*Étape précédente → [Étape 03 — K8s Core Concepts](step-03-k8s-core-concepts.md)*
*Prochaine étape → [Étape 05 — Networking](step-05-k8s-networking.md)*

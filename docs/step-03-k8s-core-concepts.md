# Étape 03 — Kubernetes Core Concepts

> **Branche :** `step-03/k8s-core-concepts`
> **CKA Section :** Core Concepts (13% de l'examen)

---

## 🎯 Objectif CKA

Maîtriser les ressources fondamentales de Kubernetes :
- **Pod** : unité de base, un ou plusieurs conteneurs
- **ReplicaSet** : garantit le nombre de replicas d'un Pod
- **Deployment** : gestion déclarative des mises à jour et rollbacks
- **Service** : exposition et accès réseau aux Pods
- **Namespace** : isolation logique des ressources

---

## 📋 Tâches de cette étape

- [ ] Créer les **Namespaces** `village-dev` et `village-prod`
- [ ] Créer les **Deployments** pour frontend (Angular) et backend (Spring Boot)
- [ ] Créer les **Services** (ClusterIP) pour la communication interne
- [ ] Tester avec `kubectl` (get, describe, logs, exec)
- [ ] Effectuer un rolling update et un rollback

---

## 📐 Manifestes Kubernetes (Core)

### Namespace
```yaml
# k8s/namespace/dev-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: village-dev
  labels:
    environment: dev
    project: village
```

### Deployment
```yaml
# Exemple simplifié d'un Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: village-frontend
  namespace: village-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: village-frontend
  template:
    metadata:
      labels:
        app: village-frontend
    spec:
      containers:
        - name: frontend
          image: ghcr.io/<username>/village-frontend:latest
          ports:
            - containerPort: 80
```

### Service (ClusterIP)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: village-frontend-svc
  namespace: village-dev
spec:
  selector:
    app: village-frontend
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

---

## 🔧 Commandes kubectl (Core Concepts)

```bash
# Appliquer les namespaces
kubectl apply -f k8s/namespace/

# Déployer le frontend
kubectl apply -f k8s/frontend/deployment.yaml
kubectl apply -f k8s/frontend/service.yaml

# Déployer le backend
kubectl apply -f k8s/backend/deployment.yaml
kubectl apply -f k8s/backend/service.yaml

# Vérifier les déploiements
kubectl get deployments -n village-dev
kubectl get pods -n village-dev
kubectl get services -n village-dev

# Décrire un pod
kubectl describe pod <pod-name> -n village-dev

# Voir les logs
kubectl logs <pod-name> -n village-dev

# Exécuter une commande dans le pod
kubectl exec -it <pod-name> -n village-dev -- /bin/sh

# Rolling update (changer la version de l'image)
kubectl set image deployment/village-frontend frontend=ghcr.io/<username>/village-frontend:v2 -n village-dev

# Vérifier le status du rollout
kubectl rollout status deployment/village-frontend -n village-dev

# Rollback
kubectl rollout undo deployment/village-frontend -n village-dev

# Historique du rollout
kubectl rollout history deployment/village-frontend -n village-dev

# Scaler un déploiement
kubectl scale deployment/village-frontend --replicas=3 -n village-dev
```

---

## ✅ Critères de validation

- [ ] Namespaces `village-dev` et `village-prod` créés
- [ ] Déploiements frontend et backend en état `Running`
- [ ] Services ClusterIP accessibles en interne
- [ ] Rolling update et rollback testés
- [ ] `kubectl get all -n village-dev` affiche toutes les ressources

---

## 🔗 Ressources

- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [KodeKloud CKA — Core Concepts](https://learn.kodekloud.com/user/courses/cka-certification-course-certified-kubernetes-administrator)

---

*Étape précédente → [Étape 02 — Docker Prerequisites](step-02-docker-prerequisites.md)*
*Prochaine étape → [Étape 04 — Configuration](step-04-k8s-configuration.md)*

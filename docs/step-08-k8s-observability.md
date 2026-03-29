# Étape 08 — Observabilité

> **Branche :** `step-08/k8s-observability`
> **CKA Section :** Observability (8% de l'examen)

---

## 🎯 Objectif CKA

Maîtriser le monitoring et l'observabilité dans Kubernetes :
- **Liveness Probe** : le conteneur est-il en vie ?
- **Readiness Probe** : le conteneur est-il prêt à recevoir du trafic ?
- **Startup Probe** : le conteneur a-t-il bien démarré ?
- **HPA** : Horizontal Pod Autoscaler (scalabilité automatique)
- **Monitoring** : metrics-server, `kubectl top`

---

## 📋 Tâches de cette étape

- [ ] Ajouter des **LivenessProbe** sur frontend et backend
- [ ] Ajouter des **ReadinessProbe** sur frontend et backend
- [ ] Configurer le **metrics-server**
- [ ] Créer un **HorizontalPodAutoscaler** pour le backend
- [ ] Tester les scénarios de failure et recovery automatique

---

## 📐 Architecture d'observabilité

```
┌─────────────────────────────────────────────────────────────┐
│                    Health Checks                             │
│                                                             │
│  LivenessProbe               ReadinessProbe                 │
│  ┌─────────────────────┐     ┌──────────────────────────┐   │
│  │  "Le pod est-il     │     │  "Le pod est-il prêt à   │   │
│  │   en vie ?"         │     │   recevoir du trafic ?"  │   │
│  │  → Redémarre le pod │     │  → Retire du Service LB  │   │
│  └─────────────────────┘     └──────────────────────────┘   │
│                                                             │
│  HPA (Horizontal Pod Autoscaler)                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  CPU > 70%  →  Scale UP   (max: 5 replicas)            │ │
│  │  CPU < 20%  →  Scale DOWN (min: 1 replica)             │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📐 Manifestes Kubernetes (Observabilité)

### Liveness et Readiness Probes (Backend Spring Boot)
```yaml
containers:
  - name: backend
    image: ghcr.io/<username>/village-backend:latest
    ports:
      - containerPort: 8080
    livenessProbe:
      httpGet:
        path: /actuator/health/liveness
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /actuator/health/readiness
        port: 8080
      initialDelaySeconds: 20
      periodSeconds: 5
      failureThreshold: 3
    startupProbe:
      httpGet:
        path: /actuator/health
        port: 8080
      failureThreshold: 30
      periodSeconds: 10
```

### Liveness et Readiness Probes (Frontend Angular/Nginx)
```yaml
containers:
  - name: frontend
    image: ghcr.io/<username>/village-frontend:latest
    ports:
      - containerPort: 80
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
```

### HorizontalPodAutoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: village-backend-hpa
  namespace: village-dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: village-backend
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

---

## 🔧 Commandes kubectl (Observabilité)

```bash
# Installer metrics-server (Minikube)
minikube addons enable metrics-server

# Installer metrics-server (Kind/Kubernetes)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Voir la consommation de ressources
kubectl top pods -n village-dev
kubectl top nodes

# Appliquer le HPA
kubectl apply -f k8s/backend/hpa.yaml
kubectl apply -f k8s/frontend/hpa.yaml

# Voir le statut du HPA
kubectl get hpa -n village-dev
kubectl describe hpa village-backend-hpa -n village-dev

# Voir les événements (pour diagnostiquer)
kubectl get events -n village-dev --sort-by='.lastTimestamp'

# Voir les logs en temps réel
kubectl logs -f <pod-name> -n village-dev

# Voir les logs des dernières 1 heure
kubectl logs --since=1h <pod-name> -n village-dev

# Voir l'état de santé des pods
kubectl get pods -n village-dev -o wide

# Simuler une panne pour tester LivenessProbe
kubectl exec -it <pod-name> -n village-dev -- kill 1
```

---

## ✅ Critères de validation

- [ ] LivenessProbe et ReadinessProbe configurées sur tous les pods
- [ ] `kubectl get pods` affiche `READY 1/1` pour tous les pods
- [ ] `kubectl top pods -n village-dev` affiche les métriques
- [ ] HPA configuré et actif (`kubectl get hpa -n village-dev`)
- [ ] Recovery automatique après simulation de panne

---

## 🔗 Ressources

- [Configure Liveness, Readiness Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [KodeKloud CKA — Observability](https://learn.kodekloud.com/user/courses/cka-certification-course-certified-kubernetes-administrator)

---

*Étape précédente → [Étape 07 — Security](step-07-k8s-security.md)*
*Prochaine étape → [Étape 09 — GitHub Actions](step-09-github-actions.md)*

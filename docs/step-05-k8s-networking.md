# Étape 05 — Networking

> **Branche :** `step-05/k8s-networking`
> **CKA Section :** Services & Networking (20% de l'examen)

---

## 🎯 Objectif CKA

Maîtriser les concepts réseau de Kubernetes :
- **Services** : ClusterIP, NodePort, LoadBalancer, ExternalName
- **Ingress** : règles de routage HTTP/HTTPS
- **DNS** : résolution de noms dans le cluster
- **NetworkPolicy** : contrôle du trafic réseau entre pods

---

## 📋 Tâches de cette étape

- [ ] Créer un **Service NodePort** pour accès externe en développement
- [ ] Créer un **Service LoadBalancer** pour la production
- [ ] Créer un **Ingress** avec règles de routage pour frontend et backend
- [ ] Créer des **NetworkPolicies** pour sécuriser les communications
- [ ] Tester la résolution DNS entre services

---

## 📐 Types de Services Kubernetes

```
┌─────────────────────────────────────────────────────────────┐
│                    Types de Services                         │
│                                                             │
│  ClusterIP (défaut)                                          │
│  ┌──────────────────────────────────────────┐               │
│  │  Accessible uniquement dans le cluster   │               │
│  │  frontend-svc → port 80                  │               │
│  └──────────────────────────────────────────┘               │
│                                                             │
│  NodePort                                                    │
│  ┌──────────────────────────────────────────┐               │
│  │  Accessible via IP du Node + port        │               │
│  │  NodeIP:30080 → frontend-svc:80          │               │
│  └──────────────────────────────────────────┘               │
│                                                             │
│  LoadBalancer                                                │
│  ┌──────────────────────────────────────────┐               │
│  │  Crée un LB externe (cloud provider)     │               │
│  │  EXTERNAL-IP:80 → frontend-svc:80        │               │
│  └──────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

## 📐 Routage avec Ingress

```
Internet
    │
    ▼
Ingress Controller (nginx)
    │
    ├── /        → village-frontend-svc:80  (Angular App)
    └── /api     → village-backend-svc:8080 (Spring Boot API)
```

---

## 📐 Manifestes Kubernetes (Networking)

### Service NodePort (dev)
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
      nodePort: 30080
  type: NodePort
```

### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: village-ingress
  namespace: village-dev
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
    - host: village.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: village-frontend-svc
                port:
                  number: 80
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: village-backend-svc
                port:
                  number: 8080
```

### NetworkPolicy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-allow-frontend
  namespace: village-dev
spec:
  podSelector:
    matchLabels:
      app: village-backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: village-frontend
      ports:
        - protocol: TCP
          port: 8080
```

---

## 🔧 Commandes kubectl (Networking)

```bash
# Appliquer l'Ingress
kubectl apply -f k8s/ingress/ingress.yaml

# Appliquer les NetworkPolicies
kubectl apply -f k8s/security/networkpolicy.yaml

# Lister les services
kubectl get services -n village-dev

# Lister les Ingress
kubectl get ingress -n village-dev

# Décrire un Ingress
kubectl describe ingress village-ingress -n village-dev

# Tester la résolution DNS dans le cluster
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup village-frontend-svc.village-dev.svc.cluster.local

# Port-forward pour tester localement
kubectl port-forward svc/village-frontend-svc 8080:80 -n village-dev

# Installer nginx-ingress-controller (Minikube)
minikube addons enable ingress

# Installer nginx-ingress-controller (Kind/Kubernetes)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Lister les NetworkPolicies
kubectl get networkpolicies -n village-dev
```

---

## 🌐 DNS Kubernetes

Format : `<service-name>.<namespace>.svc.cluster.local`

```
village-frontend-svc.village-dev.svc.cluster.local  → 10.96.x.x:80
village-backend-svc.village-dev.svc.cluster.local   → 10.96.x.x:8080
```

---

## ✅ Critères de validation

- [ ] Frontend accessible via NodePort `http://<NodeIP>:30080`
- [ ] Backend API accessible via NodePort `http://<NodeIP>:30081`
- [ ] Ingress routant correctement `/` vers frontend et `/api` vers backend
- [ ] DNS résolution testée entre services
- [ ] NetworkPolicy empêchant l'accès direct au backend depuis l'extérieur

---

## 🔗 Ressources

- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [DNS for Services](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [NetworkPolicies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

---

*Étape précédente → [Étape 04 — Configuration](step-04-k8s-configuration.md)*
*Prochaine étape → [Étape 06 — Storage](step-06-k8s-storage.md)*

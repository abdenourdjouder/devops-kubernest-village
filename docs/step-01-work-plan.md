# Étape 01 — Plan de travail

> **Branche :** `step-01/work-plan`
> **CKA Section :** Core Concepts — Architecture Kubernetes

---

## 🎯 Objectif CKA

Comprendre l'architecture complète d'un cluster Kubernetes :
- Le **Control Plane** (Master) : API Server, etcd, Scheduler, Controller Manager
- Les **Worker Nodes** : kubelet, kube-proxy, container runtime
- La communication entre les composants
- Le rôle de `kubectl` comme outil CLI

---

## 📋 Tâches de cette étape

- [x] Créer le `README.md` principal avec le plan de travail complet
- [x] Définir la structure du repository
- [x] Documenter chaque étape avec les objectifs CKA
- [x] Créer les répertoires `docs/`, `docker/`, `k8s/`, `.github/workflows/`
- [x] Créer les Dockerfiles pour frontend (Angular) et backend (Spring Boot)
- [x] Créer les manifestes Kubernetes de base
- [x] Créer les workflows GitHub Actions

---

## 🏗️ Architecture Kubernetes — Concepts de base

```
┌─────────────────────────────────────────────────────────────┐
│                    CONTROL PLANE (Master)                     │
│                                                              │
│  ┌──────────────┐  ┌──────────┐  ┌────────────────────────┐ │
│  │  API Server  │  │  etcd    │  │  Controller Manager    │ │
│  │  (kube-api)  │  │          │  │  - Node Controller     │ │
│  └──────────────┘  └──────────┘  │  - Replication Ctrl   │ │
│                                  └────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   Scheduler                           │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                    kubectl / API
                           │
┌─────────────────────────────────────────────────────────────┐
│                    WORKER NODES                               │
│                                                              │
│  ┌─────────────────────┐    ┌─────────────────────────────┐ │
│  │  Node 1              │    │  Node 2                     │ │
│  │  ┌───────────────┐  │    │  ┌───────────────────────┐  │ │
│  │  │  kubelet      │  │    │  │  kubelet              │  │ │
│  │  └───────────────┘  │    │  └───────────────────────┘  │ │
│  │  ┌───────────────┐  │    │  ┌───────────────────────┐  │ │
│  │  │  kube-proxy   │  │    │  │  kube-proxy           │  │ │
│  │  └───────────────┘  │    │  └───────────────────────┘  │ │
│  │  ┌───────────────┐  │    │  ┌───────────────────────┐  │ │
│  │  │  Pods         │  │    │  │  Pods                 │  │ │
│  │  └───────────────┘  │    │  └───────────────────────┘  │ │
│  └─────────────────────┘    └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📚 Commandes kubectl de base (à maîtriser)

```bash
# Vérifier la version
kubectl version --client

# Informations sur le cluster
kubectl cluster-info

# Lister les noeuds
kubectl get nodes

# Lister tous les pods dans tous les namespaces
kubectl get pods --all-namespaces

# Créer un pod de test
kubectl run nginx --image=nginx

# Décrire une ressource
kubectl describe pod nginx

# Supprimer une ressource
kubectl delete pod nginx

# Appliquer un manifeste YAML
kubectl apply -f manifest.yaml

# Voir les logs d'un pod
kubectl logs <pod-name>

# Exécuter une commande dans un pod
kubectl exec -it <pod-name> -- /bin/bash
```

---

## 🔗 Ressources

- [Architecture Kubernetes](https://kubernetes.io/docs/concepts/overview/components/)
- [KodeKloud CKA — Core Concepts](https://learn.kodekloud.com/user/courses/cka-certification-course-certified-kubernetes-administrator)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

## ✅ Critères de validation

- [ ] Structure du repository créée et pushée sur GitHub
- [ ] README complet avec plan de travail
- [ ] Comprendre l'architecture K8s (pour l'examen CKA)
- [ ] `kubectl` installé et configuré localement

---

*Prochaine étape → [Étape 02 — Docker Prerequisites](step-02-docker-prerequisites.md)*

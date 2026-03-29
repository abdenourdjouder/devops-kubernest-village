# 🚀 DevOps KuberNest Village — Kubernetes Portfolio Project

> **Projet éducatif** : Déploiement d'une application Angular + Spring Boot sur Kubernetes, en corrélation avec la certification **CKA (Certified Kubernetes Administrator)**.
> Application source : [village](https://github.com/abdenourdjouder/village)

---

## 🎯 Objectifs du projet

1. **Préparer la certification CKA** (Certified Kubernetes Administrator) via la mise en pratique
2. **Construire un portfolio GitHub** avec un vrai projet Kubernetes étape par étape
3. **Conteneuriser** une application Angular (frontend) + Spring Boot (backend)
4. **Déployer** sur Kubernetes avec les manifestes YAML et `kubectl`
5. **Automatiser** le déploiement avec **GitHub Actions** (CI/CD) sur les environnements `DEV` et `PROD`

---

## 📚 Corrélation avec le cours CKA (KodeKloud)

| Étape | Branche | Sujet CKA | Thème CKA |
|-------|---------|-----------|-----------|
| 01 | `step-01/work-plan` | Core Concepts | Architecture K8s, composants du cluster |
| 02 | `step-02/docker-prerequisites` | — | Docker Build, images, conteneurs |
| 03 | `step-03/k8s-core-concepts` | Core Concepts | Pods, ReplicaSets, Deployments |
| 04 | `step-04/k8s-configuration` | Configuration | ConfigMaps, Secrets, namespaces, resource limits |
| 05 | `step-05/k8s-networking` | Services & Networking | Services, Ingress, DNS, NetworkPolicies |
| 06 | `step-06/k8s-storage` | Storage | PersistentVolumes, PersistentVolumeClaims |
| 07 | `step-07/k8s-security` | Security | RBAC, ServiceAccounts, SecurityContext |
| 08 | `step-08/k8s-observability` | Observability | Probes, Logs, Metrics, HPA |
| 09 | `step-09/github-actions` | — | CI/CD Pipeline, GitHub Actions |
| 10 | `step-10/auto-deploy-dev-prod` | Cluster Maintenance | Multi-environnement, Rolling Updates, Rollbacks |

---

## 🗺️ Plan de travail détaillé

### ✅ Étape 01 — Plan de travail (`step-01/work-plan`)
**Objectif :** Définir l'architecture du projet et créer le plan de travail.
- Création du `README.md` complet
- Structure du repository
- Documentation de chaque étape
- **CKA :** Comprendre l'architecture Kubernetes (Master node, Worker nodes, etcd, API Server, Scheduler, Controller Manager)

### 🐳 Étape 02 — Prérequis Docker (`step-02/docker-prerequisites`)
**Objectif :** Conteneuriser les deux microservices Angular et Spring Boot.
- `Dockerfile` pour le frontend Angular (multi-stage build + Nginx)
- `Dockerfile` pour le backend Spring Boot (multi-stage build)
- `docker-compose.yml` pour les tests locaux
- Tests de build et run des images Docker
- **CKA :** Maîtriser les concepts de conteneurs (la base de K8s)

### ⚙️ Étape 03 — Manifestes K8s Core (`step-03/k8s-core-concepts`)
**Objectif :** Déployer l'application avec les ressources Kubernetes de base.
- Création des `Namespace` (dev / prod)
- `Pod`, `ReplicaSet`, `Deployment` pour frontend et backend
- `Service` (ClusterIP) pour la communication interne
- Tests avec `kubectl get`, `kubectl describe`, `kubectl logs`
- **CKA :** Pods, ReplicaSets, Deployments, Services (Section "Core Concepts")

### 🔧 Étape 04 — Configuration (`step-04/k8s-configuration`)
**Objectif :** Externaliser la configuration et gérer les secrets.
- `ConfigMap` pour les variables d'environnement
- `Secret` pour les données sensibles (DB passwords, API keys)
- `ResourceRequests` et `ResourceLimits` pour les conteneurs
- Variables d'environnement injectées dans les pods
- **CKA :** ConfigMaps, Secrets, Resource Requirements (Section "Configuration")

### 🌐 Étape 05 — Networking (`step-05/k8s-networking`)
**Objectif :** Exposer l'application et gérer le réseau.
- `Service` NodePort / LoadBalancer pour exposition externe
- `Ingress` avec règles de routage (frontend / backend / api)
- `NetworkPolicy` pour sécuriser les communications inter-pods
- **CKA :** Services, Ingress, DNS, NetworkPolicies (Section "Services & Networking")

### 💾 Étape 06 — Storage (`step-06/k8s-storage`)
**Objectif :** Persister les données (base de données).
- `PersistentVolume` (PV) et `PersistentVolumeClaim` (PVC)
- Déploiement d'une base de données (PostgreSQL/MySQL) avec stockage persistant
- `StorageClass` pour le provisionnement dynamique
- **CKA :** PV, PVC, StorageClasses (Section "Storage")

### 🔒 Étape 07 — Security (`step-07/k8s-security`)
**Objectif :** Sécuriser le cluster et les applications.
- `ServiceAccount` dédié par microservice
- `Role` et `RoleBinding` (RBAC)
- `ClusterRole` et `ClusterRoleBinding`
- `SecurityContext` pour les pods
- **CKA :** RBAC, ServiceAccounts, SecurityContext (Section "Security")

### 📊 Étape 08 — Observabilité (`step-08/k8s-observability`)
**Objectif :** Monitorer et assurer la disponibilité.
- `LivenessProbe` et `ReadinessProbe` pour les deux services
- `HorizontalPodAutoscaler` (HPA)
- Configuration du `metrics-server`
- Consultation des logs avec `kubectl logs`
- **CKA :** Liveness/Readiness Probes, Monitoring, Logging (Section "Observability")

### 🔄 Étape 09 — GitHub Actions CI/CD (`step-09/github-actions`)
**Objectif :** Automatiser le build et les tests.
- Workflow de build des images Docker (frontend + backend)
- Push des images vers un registry (Docker Hub / GHCR)
- Tests automatiques à chaque commit
- **CKA :** Maîtrise des outils DevOps complémentaires

### 🚀 Étape 10 — Auto-déploiement DEV/PROD (`step-10/auto-deploy-dev-prod`)
**Objectif :** Déploiement automatique sur deux environnements.
- Workflow GitHub Actions pour déploiement sur `DEV` (branche `develop`)
- Workflow GitHub Actions pour déploiement sur `PROD` (branche `main`)
- Rolling updates et stratégie de rollback
- Gestion des secrets GitHub Actions (kubeconfig, registry)
- **CKA :** Cluster Maintenance, Rolling Updates, Rollbacks (Section "Cluster Maintenance")

---

## 🏗️ Architecture du projet

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────────┐ │
│  │  Push    │───▶│ GitHub       │───▶│ Docker Registry    │ │
│  │  Code    │    │ Actions CI   │    │ (GHCR/Docker Hub)  │ │
│  └──────────┘    └──────────────┘    └────────────────────┘ │
└──────────────────────────┬──────────────────────────────────┘
                           │ kubectl apply
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                          │
│  ┌────────────────────┐    ┌────────────────────────────┐   │
│  │  Namespace: dev    │    │  Namespace: prod            │   │
│  │                    │    │                             │   │
│  │  ┌──────────────┐  │    │  ┌──────────────────────┐  │   │
│  │  │  Frontend    │  │    │  │  Frontend (Angular)  │  │   │
│  │  │  (Angular)   │  │    │  │  Replicas: 2         │  │   │
│  │  │  Replicas: 1 │  │    │  └──────────────────────┘  │   │
│  │  └──────────────┘  │    │  ┌──────────────────────┐  │   │
│  │  ┌──────────────┐  │    │  │  Backend (Spring)    │  │   │
│  │  │  Backend     │  │    │  │  Replicas: 2         │  │   │
│  │  │  (Spring)    │  │    │  └──────────────────────┘  │   │
│  │  │  Replicas: 1 │  │    │  ┌──────────────────────┐  │   │
│  │  └──────────────┘  │    │  │  Database            │  │   │
│  │                    │    │  │  (PostgreSQL + PVC)  │  │   │
│  └────────────────────┘    │  └──────────────────────┘  │   │
│                            └────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Structure du repository

```
devops-kubernest-village/
├── README.md                          # Ce fichier — plan du projet
├── docs/                              # Documentation détaillée par étape
│   ├── step-01-work-plan.md
│   ├── step-02-docker-prerequisites.md
│   ├── step-03-k8s-core-concepts.md
│   ├── step-04-k8s-configuration.md
│   ├── step-05-k8s-networking.md
│   ├── step-06-k8s-storage.md
│   ├── step-07-k8s-security.md
│   ├── step-08-k8s-observability.md
│   ├── step-09-github-actions.md
│   └── step-10-auto-deploy-dev-prod.md
├── docker/                            # Dockerfiles et docker-compose
│   ├── frontend/
│   │   ├── Dockerfile
│   │   └── nginx.conf
│   ├── backend/
│   │   └── Dockerfile
│   └── docker-compose.yml
├── k8s/                               # Manifestes Kubernetes
│   ├── namespace/
│   │   ├── dev-namespace.yaml
│   │   └── prod-namespace.yaml
│   ├── frontend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   └── hpa.yaml
│   ├── backend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   └── hpa.yaml
│   ├── ingress/
│   │   └── ingress.yaml
│   ├── storage/
│   │   ├── pv.yaml
│   │   └── pvc.yaml
│   └── security/
│       ├── serviceaccount.yaml
│       ├── rbac.yaml
│       └── networkpolicy.yaml
├── .github/
│   └── workflows/
│       ├── ci-build.yml               # CI: build + tests sur chaque PR
│       ├── cd-dev.yml                 # CD: déploiement auto sur DEV
│       └── cd-prod.yml                # CD: déploiement auto sur PROD
└── scripts/
    ├── setup-cluster.sh               # Script d'initialisation du cluster
    ├── deploy-dev.sh                  # Script de déploiement DEV
    └── deploy-prod.sh                 # Script de déploiement PROD
```

---

## 🚀 Démarrage rapide

### Prérequis
- Docker Desktop / Docker Engine
- `kubectl` CLI
- Minikube ou Kind (développement local) ou un cluster K8s
- Java 17+ et Maven (pour le backend Spring Boot)
- Node.js 18+ et Angular CLI (pour le frontend Angular)

### 1. Cloner les projets
```bash
# Ce repository (DevOps)
git clone https://github.com/abdenourdjouder/devops-kubernest-village.git

# Application source
git clone https://github.com/abdenourdjouder/village.git
```

### 2. Build Docker local
```bash
# Build et run avec docker-compose
docker-compose -f docker/docker-compose.yml up --build
```

### 3. Déploiement Kubernetes (dev)
```bash
# Créer les namespaces
kubectl apply -f k8s/namespace/

# Déployer frontend + backend + ingress
kubectl apply -f k8s/frontend/
kubectl apply -f k8s/backend/
kubectl apply -f k8s/ingress/

# Vérifier le déploiement
kubectl get all -n village-dev
```

---

## 🔗 Ressources utiles

| Ressource | Lien |
|-----------|------|
| Cours CKA KodeKloud | https://learn.kodekloud.com/user/courses/cka-certification-course-certified-kubernetes-administrator |
| Application source (Village) | https://github.com/abdenourdjouder/village |
| Documentation Kubernetes | https://kubernetes.io/docs/ |
| Docker Documentation | https://docs.docker.com/ |
| GitHub Actions Docs | https://docs.github.com/en/actions |
| CNCF Landscape | https://landscape.cncf.io/ |

---

## 📈 Suivi de progression

| Étape | Statut | Branche | Notes |
|-------|--------|---------|-------|
| 01 - Plan de travail | ✅ Complété | `step-01/work-plan` | Structure du projet définie |
| 02 - Docker | 🔄 En cours | `step-02/docker-prerequisites` | |
| 03 - K8s Core | ⏳ À faire | `step-03/k8s-core-concepts` | |
| 04 - Configuration | ⏳ À faire | `step-04/k8s-configuration` | |
| 05 - Networking | ⏳ À faire | `step-05/k8s-networking` | |
| 06 - Storage | ⏳ À faire | `step-06/k8s-storage` | |
| 07 - Security | ⏳ À faire | `step-07/k8s-security` | |
| 08 - Observabilité | ⏳ À faire | `step-08/k8s-observability` | |
| 09 - GitHub Actions | ⏳ À faire | `step-09/github-actions` | |
| 10 - Auto-deploy | ⏳ À faire | `step-10/auto-deploy-dev-prod` | |

---

*Projet réalisé par [abdenourdjouder](https://github.com/abdenourdjouder) — Portfolio Kubernetes & DevOps*
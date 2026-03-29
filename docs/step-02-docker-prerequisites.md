# Étape 02 — Prérequis Docker

> **Branche :** `step-02/docker-prerequisites`
> **CKA Section :** Prérequis — Conteneurs et Images Docker

---

## 🎯 Objectif CKA

Maîtriser les concepts de conteneurs, qui sont la base de Kubernetes :
- Créer des **Dockerfiles** optimisés (multi-stage builds)
- Builder des **images Docker** légères et sécurisées
- Tester les **conteneurs** en local
- Comprendre les **registries** d'images (Docker Hub, GHCR)

---

## 📋 Tâches de cette étape

- [ ] Cloner l'application [village](https://github.com/abdenourdjouder/village)
- [ ] Créer le `Dockerfile` multi-stage pour le **frontend Angular**
- [ ] Créer le `Dockerfile` multi-stage pour le **backend Spring Boot**
- [ ] Créer le `nginx.conf` pour le frontend
- [ ] Créer le `docker-compose.yml` pour les tests locaux
- [ ] Builder les images Docker
- [ ] Tester les conteneurs localement
- [ ] Pousser les images sur le registry (Docker Hub / GHCR)

---

## 🐳 Architecture Docker

```
Application Village
│
├── Frontend (Angular)
│   ├── Stage 1 (build): node:18-alpine → ng build --configuration=production
│   └── Stage 2 (serve): nginx:alpine → copier dist/ + nginx.conf
│
└── Backend (Spring Boot)
    ├── Stage 1 (build): maven:3.9-eclipse-temurin-17 → mvn package
    └── Stage 2 (run):   eclipse-temurin:17-jre-alpine → java -jar app.jar
```

---

## 📦 Images Docker

| Service | Image | Port | Registry |
|---------|-------|------|----------|
| Frontend (Angular) | `village-frontend:latest` | 80 | GHCR / Docker Hub |
| Backend (Spring Boot) | `village-backend:latest` | 8080 | GHCR / Docker Hub |

---

## 🔧 Commandes Docker

```bash
# Build du frontend
docker build -t village-frontend:latest ./docker/frontend/

# Build du backend (nécessite le code source de village)
docker build -t village-backend:latest ./docker/backend/

# Ou avec docker-compose
docker-compose -f docker/docker-compose.yml build

# Démarrer les deux services
docker-compose -f docker/docker-compose.yml up -d

# Vérifier les conteneurs en cours
docker ps

# Voir les logs
docker logs village-frontend
docker logs village-backend

# Tester le frontend
curl http://localhost:4200

# Tester l'API backend
curl http://localhost:8080/api/health

# Arrêter les services
docker-compose -f docker/docker-compose.yml down

# Pousser les images vers GHCR
docker tag village-frontend:latest ghcr.io/<username>/village-frontend:latest
docker push ghcr.io/<username>/village-frontend:latest

docker tag village-backend:latest ghcr.io/<username>/village-backend:latest
docker push ghcr.io/<username>/village-backend:latest
```

---

## ✅ Critères de validation

- [ ] `docker build` réussi pour le frontend Angular
- [ ] `docker build` réussi pour le backend Spring Boot
- [ ] `docker-compose up` démarre les deux services sans erreur
- [ ] Frontend accessible sur `http://localhost:4200`
- [ ] Backend accessible sur `http://localhost:8080`
- [ ] Images poussées sur le registry

---

## 🔗 Ressources

- [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Nginx for Angular](https://angular.io/guide/deployment#nginx)

---

*Étape précédente → [Étape 01 — Plan de travail](step-01-work-plan.md)*
*Prochaine étape → [Étape 03 — K8s Core Concepts](step-03-k8s-core-concepts.md)*

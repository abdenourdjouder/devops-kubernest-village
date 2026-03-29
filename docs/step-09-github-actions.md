# Étape 09 — GitHub Actions CI/CD

> **Branche :** `step-09/github-actions`
> **CKA Section :** Compétences DevOps complémentaires

---

## 🎯 Objectif

Automatiser le build, les tests et la publication des images Docker :
- **CI Pipeline** : build + tests à chaque Pull Request
- **CD Pipeline** : publication des images vers GHCR
- **Secrets GitHub** : gestion sécurisée des credentials
- **Caching** : optimiser les builds avec le cache Docker/Maven/npm

---

## 📋 Tâches de cette étape

- [ ] Créer le workflow **CI Build** (`ci-build.yml`) pour les PR
- [ ] Créer le workflow **CD Build & Push** pour main/develop
- [ ] Configurer les **GitHub Secrets** pour GHCR et Kubernetes
- [ ] Tester le déclenchement des workflows
- [ ] Optimiser avec le **cache** npm/Maven/Docker

---

## 📐 Architecture CI/CD

```
GitHub Repository
       │
       ├── Pull Request ──────────► ci-build.yml
       │                             │
       │                             ├── Checkout code
       │                             ├── Build frontend (ng build)
       │                             ├── Build backend (mvn test)
       │                             └── Build Docker images (no push)
       │
       ├── Push to develop ─────────► cd-dev.yml
       │                              │
       │                              ├── Build Docker images
       │                              ├── Push to GHCR (tag: dev-latest)
       │                              └── Deploy to village-dev namespace
       │
       └── Push to main ───────────► cd-prod.yml
                                      │
                                      ├── Build Docker images
                                      ├── Push to GHCR (tag: v1.x.x / latest)
                                      └── Deploy to village-prod namespace
```

---

## 🔑 Secrets GitHub requis

| Secret Name | Description | Exemple |
|-------------|-------------|---------|
| `GHCR_TOKEN` | GitHub Container Registry token | `ghp_xxxxxxxxxxxx` |
| `KUBE_CONFIG_DEV` | kubeconfig pour l'environnement DEV | `base64(kubeconfig)` |
| `KUBE_CONFIG_PROD` | kubeconfig pour l'environnement PROD | `base64(kubeconfig)` |
| `DOCKERHUB_USERNAME` | Docker Hub username (optionnel) | `myusername` |
| `DOCKERHUB_TOKEN` | Docker Hub access token (optionnel) | `dckr_pat_xxxx` |

### Comment configurer les secrets

```bash
# Encoder le kubeconfig en base64
cat ~/.kube/config | base64 -w 0

# Aller dans GitHub → Settings → Secrets → Actions
# Ajouter chaque secret avec le nom et la valeur
```

---

## 📐 Workflow CI Build (extrait)

```yaml
# .github/workflows/ci-build.yml
name: CI - Build & Test

on:
  pull_request:
    branches: [main, develop]

jobs:
  build-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          repository: abdenourdjouder/village
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      - run: cd frontend && npm ci && npm run build -- --configuration=production

  build-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          repository: abdenourdjouder/village
      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: 'maven'
      - run: cd backend && mvn test --no-transfer-progress
```

---

## 🔧 Commandes pour tester les workflows

```bash
# Déclencher manuellement un workflow
# GitHub → Actions → Select workflow → Run workflow

# Voir les runs GitHub Actions via gh CLI
gh run list

# Voir les logs d'un run
gh run view <run-id> --log

# Vérifier les images dans GHCR
# https://github.com/<username>?tab=packages
```

---

## ✅ Critères de validation

- [ ] Workflow `ci-build.yml` déclenché sur chaque PR
- [ ] Build Angular réussi dans le workflow CI
- [ ] Build/Tests Spring Boot réussis dans le workflow CI
- [ ] Images Docker buildées et poussées sur GHCR
- [ ] Secrets GitHub configurés correctement
- [ ] Badges de status du workflow dans le README

---

## 🔗 Ressources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Action](https://github.com/docker/build-push-action)
- [GHCR with GitHub Actions](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

*Étape précédente → [Étape 08 — Observabilité](step-08-k8s-observability.md)*
*Prochaine étape → [Étape 10 — Auto-déploiement DEV/PROD](step-10-auto-deploy-dev-prod.md)*

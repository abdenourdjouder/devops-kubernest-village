# 🧪 Village DevOps — Guide Pratique LABs

> **Application cible :** Angular (frontend) + Spring Boot (backend) + PostgreSQL  
> **Objectif :** Reproduire entièrement le projet `devops-kubernetes-village` étape par étape, à la main, comme si tu partais de zéro.  
> **Niveau :** Intermédiaire — corrélé avec la certification **CKA (Certified Kubernetes Administrator)**

---

## 📋 Table des matières

| LAB | Sujet | Durée estimée |
|-----|-------|---------------|
| [LAB 01](#lab-01--architecture--plan-de-travail) | Architecture & Plan de travail | 30 min |
| [LAB 02](#lab-02--conteneurisation-docker) | Conteneurisation Docker | 1h30 |
| [LAB 03](#lab-03--manifestes-kubernetes-core) | Manifestes Kubernetes Core | 1h |
| [LAB 04](#lab-04--configuration-configmaps--secrets) | Configuration : ConfigMaps & Secrets | 45 min |
| [LAB 05](#lab-05--networking--ingress) | Networking & Ingress | 1h |
| [LAB 06](#lab-06--storage-persistantvolume--pvc) | Storage : PersistentVolume & PVC | 45 min |
| [LAB 07](#lab-07--sécurité-rbac--serviceaccounts) | Sécurité : RBAC & ServiceAccounts | 1h |
| [LAB 08](#lab-08--observabilité-probes--hpa) | Observabilité : Probes & HPA | 45 min |
| [LAB 09](#lab-09--cicd-github-actions) | CI/CD GitHub Actions | 1h30 |
| [LAB 10](#lab-10--déploiement-automatique-dev--prod) | Déploiement automatique DEV / PROD | 1h |

---

## 🛠️ Prérequis globaux

Avant de commencer, assure-toi d'avoir installé les outils suivants :

```bash
# Vérifier Docker
docker --version
# → Docker version 24.x ou supérieur

# Vérifier kubectl
kubectl version --client
# → Client Version: v1.28.x ou supérieur

# Vérifier Minikube
minikube version
# → minikube version: v1.31.x ou supérieur

# Vérifier Git
git --version

# Vérifier Node.js (pour le frontend Angular)
node --version    # → v18.x ou supérieur
npm --version

# Vérifier Java (pour le backend Spring Boot)
java -version     # → 17.x ou supérieur
mvn -version      # Maven 3.9.x
```

### Cloner les deux repositories

```bash
# 1. Repository DevOps (ce projet)
git clone https://github.com/abdenourdjouder/devops-kubernetes-village.git
cd devops-kubernetes-village

# 2. Application source (côte à côte)
cd ..
git clone https://github.com/abdenourdjouder/village.git

# Vérifier la structure
ls -la
# → devops-kubernetes-village/
# → village/
```

---

## LAB 01 — Architecture & Plan de travail

> **CKA :** Core Concepts — Architecture Kubernetes (Master Node, Worker Node, etcd, API Server)  
> **Objectif :** Comprendre l'architecture du projet et du cluster Kubernetes avant de coder.

### 🎯 Objectifs du LAB

- Comprendre les composants d'un cluster Kubernetes
- Démarrer Minikube et explorer le cluster
- Visualiser l'architecture du projet Village

### Étape 1.1 — Démarrer Minikube

```bash
# Démarrer Minikube avec des ressources suffisantes
minikube start --cpus=2 --memory=4096 --driver=docker

# Vérifier que le cluster est actif
kubectl cluster-info

# Voir les noeuds du cluster
kubectl get nodes
# → NAME       STATUS   ROLES           AGE   VERSION
# → minikube   Ready    control-plane   ...   v1.28.x

# Voir les composants du control plane
kubectl get pods -n kube-system
```

### Étape 1.2 — Explorer l'architecture K8s

```bash
# Voir tous les namespaces existants
kubectl get namespaces

# Voir les ressources disponibles dans le cluster
kubectl api-resources | head -30

# Décrire le noeud Minikube (voir les ressources disponibles)
kubectl describe node minikube
```

### Étape 1.3 — Explorer le repository

```bash
# Se placer dans le repository DevOps
cd devops-kubernetes-village

# Voir la structure complète
find . -type f | grep -v ".git" | sort

# Lire le README principal
cat README.md
```

### ✅ Vérification LAB 01

```bash
kubectl get nodes
# → minikube   Ready   control-plane   ...

kubectl get pods -n kube-system | grep -E "etcd|apiserver|scheduler|controller"
# → kube-apiserver-minikube       Running
# → etcd-minikube                 Running
# → kube-controller-manager-...   Running
# → kube-scheduler-minikube       Running
```

> 💡 **Ce que tu viens d'apprendre :** Le control plane d'un cluster K8s est composé de l'API Server (point d'entrée), etcd (base de données), le Scheduler (planificateur) et le Controller Manager (contrôleur de l'état désiré).

---

## LAB 02 — Conteneurisation Docker

> **CKA :** Maîtrise des conteneurs (fondation de Kubernetes)  
> **Objectif :** Créer les Dockerfiles pour Angular et Spring Boot, tester en local avec docker-compose.

### 🎯 Objectifs du LAB

- Comprendre le multi-stage build Docker
- Conteneuriser le frontend Angular (Nginx)
- Conteneuriser le backend Spring Boot
- Tester l'application complète avec docker-compose

### Étape 2.1 — Examiner les Dockerfiles existants

```bash
# Voir le Dockerfile frontend (multi-stage build)
cat docker/frontend/Dockerfile

# Voir la configuration Nginx
cat docker/frontend/nginx.conf

# Voir le Dockerfile backend (multi-stage build)
cat docker/backend/Dockerfile
```

### Étape 2.2 — Comprendre le multi-stage build

Le multi-stage build permet d'avoir **une image finale légère** (sans les outils de build) :

```
Stage 1 (builder) :  node:18-alpine     → npm ci + npm run build
Stage 2 (runtime) :  nginx:1.25-alpine  → seulement les fichiers buildés
```

```bash
# Build manuel de l'image frontend (depuis le dossier village/frontend)
cd ../village
docker build \
  -t village-frontend:local \
  -f ../devops-kubernetes-village/docker/frontend/Dockerfile \
  ./frontend

# Vérifier la taille de l'image
docker images village-frontend:local
# → Une image légère ~50-80MB grâce au multi-stage

# Build manuel de l'image backend (depuis le dossier village/backend)
docker build \
  -t village-backend:local \
  -f ../devops-kubernetes-village/docker/backend/Dockerfile \
  ./backend

# Vérifier les deux images
docker images | grep village
```

### Étape 2.3 — Lancer avec docker-compose

```bash
# Retourner dans le repository DevOps
cd ../devops-kubernetes-village

# Voir le fichier docker-compose
cat docker/docker-compose.yml

# Lancer tous les services (frontend + backend + postgres)
# Note: les contextes de build pointent vers ../village/
cd docker
DB_PASSWORD=village123 docker-compose up --build -d

# Vérifier que les 3 services tournent
docker-compose ps
# → village-frontend   Up   0.0.0.0:4200->80/tcp
# → village-backend    Up   0.0.0.0:8080->8080/tcp
# → village-postgres   Up   0.0.0.0:5432->5432/tcp

# Voir les logs
docker-compose logs -f backend
# Attendre "Started VillageApplication in X seconds"
```

### Étape 2.4 — Tester l'application

```bash
# Tester le frontend (doit retourner du HTML)
curl -s http://localhost:4200 | head -5

# Tester le backend (Spring Boot Actuator)
curl -s http://localhost:8080/actuator/health | python3 -m json.tool
# → { "status": "UP" }

# Tester la connexion base de données
docker exec village-postgres psql -U village -d villagedb -c "\dt"
```

### Étape 2.5 — Nettoyer

```bash
# Arrêter et supprimer les conteneurs
docker-compose down

# Supprimer aussi les volumes (repart de zéro)
docker-compose down -v

cd ..
```

### ✅ Vérification LAB 02

```bash
# Les deux images doivent exister
docker images | grep village
# → village-frontend   local   ...   ~80MB
# → village-backend    local   ...   ~150MB
```

> 💡 **Ce que tu viens d'apprendre :** Le multi-stage build Docker réduit drastiquement la taille des images. En production, on veut des images légères et sécurisées (utilisateur non-root, pas d'outils de build).

---

## LAB 03 — Manifestes Kubernetes Core

> **CKA :** Section "Core Concepts" — Pods, ReplicaSets, Deployments, Services  
> **Objectif :** Déployer l'application sur Kubernetes avec les ressources de base.

### 🎯 Objectifs du LAB

- Créer des Namespaces
- Créer des Deployments pour frontend et backend
- Créer des Services (ClusterIP) pour la communication interne
- Utiliser `kubectl` pour inspecter les ressources

### Étape 3.1 — Créer les Namespaces

```bash
# Se placer dans le repository
cd devops-kubernetes-village

# Voir les manifestes namespace
cat k8s/namespace/dev-namespace.yaml
cat k8s/namespace/prod-namespace.yaml

# Créer les namespaces
kubectl apply -f k8s/namespace/dev-namespace.yaml
kubectl apply -f k8s/namespace/prod-namespace.yaml

# Vérifier
kubectl get namespaces | grep village
# → village-dev    Active   ...
# → village-prod   Active   ...

# Voir les labels du namespace dev
kubectl describe namespace village-dev
```

### Étape 3.2 — Comprendre le Deployment

```bash
# Lire le manifeste du Deployment frontend
cat k8s/frontend/deployment.yaml

# Points importants à noter :
# - spec.replicas: 1          → 1 pod
# - strategy.type: RollingUpdate  → mise à jour sans downtime
# - spec.selector.matchLabels  → doit correspondre aux labels du pod
# - resources.requests/limits  → limites CPU/mémoire
# - livenessProbe/readinessProbe → sondes de santé
```

### Étape 3.3 — Appliquer les manifestes de base

Avant de déployer, il faut créer les dépendances (Security, ConfigMaps, Secrets) :

```bash
# 1. ServiceAccounts (nécessaires pour les Deployments)
kubectl apply -f k8s/security/serviceaccount.yaml
kubectl get serviceaccounts -n village-dev

# 2. ConfigMaps (variables d'environnement non-sensibles)
kubectl apply -f k8s/frontend/configmap.yaml
kubectl apply -f k8s/backend/configmap.yaml
kubectl get configmaps -n village-dev

# 3. Secret backend (mot de passe DB + JWT)
kubectl create secret generic backend-secret \
  --from-literal=DB_PASSWORD="village123" \
  --from-literal=JWT_SECRET="my-super-secret-jwt-key-change-in-prod" \
  --namespace=village-dev

# Vérifier le secret (les valeurs sont encodées en base64)
kubectl get secret backend-secret -n village-dev
kubectl describe secret backend-secret -n village-dev
```

### Étape 3.4 — Déployer le frontend

```bash
# Appliquer le Deployment frontend
kubectl apply -f k8s/frontend/deployment.yaml

# Suivre le déploiement en temps réel
kubectl rollout status deployment/village-frontend -n village-dev

# Vérifier les pods
kubectl get pods -n village-dev -l app=village-frontend
# → village-frontend-xxxxx-yyy   1/1   Running   0   ...

# Voir les détails du pod
kubectl describe pod -l app=village-frontend -n village-dev

# Voir les logs du frontend
kubectl logs -l app=village-frontend -n village-dev
```

### Étape 3.5 — Déployer le backend

```bash
# Appliquer le Deployment backend
kubectl apply -f k8s/backend/deployment.yaml

# Suivre le déploiement (Spring Boot prend ~60s à démarrer)
kubectl rollout status deployment/village-backend -n village-dev --timeout=300s

# Voir les pods en temps réel
kubectl get pods -n village-dev -w
# Ctrl+C pour arrêter le watch

# Voir les logs backend (attendre le message de démarrage)
kubectl logs -f deployment/village-backend -n village-dev
# → Started VillageApplication in X.XXX seconds
```

### Étape 3.6 — Créer les Services

```bash
# Voir les manifestes Service
cat k8s/frontend/service.yaml
cat k8s/backend/service.yaml

# Appliquer les Services
kubectl apply -f k8s/frontend/service.yaml
kubectl apply -f k8s/backend/service.yaml

# Vérifier les Services
kubectl get services -n village-dev
# → village-frontend-svc   ClusterIP   10.x.x.x   80/TCP     ...
# → village-backend-svc    ClusterIP   10.x.x.x   8080/TCP   ...

# Voir les endpoints (IPs des pods)
kubectl get endpoints -n village-dev
```

### Étape 3.7 — Inspecter l'ensemble

```bash
# Voir toutes les ressources du namespace dev
kubectl get all -n village-dev

# Tester la communication interne (depuis un pod temporaire)
kubectl run test-pod --image=busybox --restart=Never -n village-dev -- \
  wget -qO- http://village-frontend-svc:80 | head -3
kubectl delete pod test-pod -n village-dev
```

### ✅ Vérification LAB 03

```bash
kubectl get pods -n village-dev
# → village-frontend-xxxxx   1/1   Running   0   ...
# → village-backend-xxxxx    1/1   Running   0   ...

kubectl get deployments -n village-dev
# → village-frontend   1/1   1   1   ...
# → village-backend    1/1   1   1   ...

kubectl get services -n village-dev
# → village-frontend-svc   ClusterIP   ...   80/TCP
# → village-backend-svc    ClusterIP   ...   8080/TCP
```

> 💡 **Ce que tu viens d'apprendre :** Un Deployment gère le cycle de vie des pods (réplication, rolling update, rollback). Un Service expose les pods via une IP stable, même si les pods sont recréés.

---

## LAB 04 — Configuration : ConfigMaps & Secrets

> **CKA :** Section "Configuration" — ConfigMaps, Secrets, Resource Limits  
> **Objectif :** Externaliser la configuration et gérer les données sensibles.

### 🎯 Objectifs du LAB

- Créer et modifier des ConfigMaps
- Créer et utiliser des Secrets de manière sécurisée
- Injecter la configuration dans les pods
- Comprendre l'encodage base64 des Secrets

### Étape 4.1 — Explorer les ConfigMaps existants

```bash
# Voir le ConfigMap frontend
cat k8s/frontend/configmap.yaml

# Voir le ConfigMap backend
cat k8s/backend/configmap.yaml

# Voir le ConfigMap créé dans le cluster
kubectl get configmap frontend-config -n village-dev -o yaml
kubectl get configmap backend-config -n village-dev -o yaml

# Voir les valeurs d'une clé spécifique
kubectl get configmap frontend-config -n village-dev \
  -o jsonpath='{.data.API_URL}'
```

### Étape 4.2 — Modifier un ConfigMap et recharger

```bash
# Modifier le ConfigMap frontend (changer le titre de l'app)
kubectl patch configmap frontend-config -n village-dev \
  --patch '{"data": {"APP_TITLE": "Village App - DEV (LAB)"}}'

# Vérifier la modification
kubectl get configmap frontend-config -n village-dev -o yaml | grep APP_TITLE

# Les pods doivent être redémarrés pour prendre en compte le changement
kubectl rollout restart deployment/village-frontend -n village-dev
kubectl rollout status deployment/village-frontend -n village-dev
```

### Étape 4.3 — Comprendre les Secrets

```bash
# Voir le secret existant (valeurs encodées en base64)
kubectl get secret backend-secret -n village-dev -o yaml

# Décoder la valeur DB_PASSWORD
kubectl get secret backend-secret -n village-dev \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 --decode
# → village123

# Encoder une valeur manuellement
echo -n "mon-nouveau-password" | base64
# → bW9uLW5vdXZlYXUtcGFzc3dvcmQ=
```

### Étape 4.4 — Créer un Secret avec différentes méthodes

```bash
# Méthode 1 — Via kubectl create (recommandée pour le lab)
kubectl create secret generic test-secret \
  --from-literal=key1="valeur1" \
  --from-literal=key2="valeur2" \
  --namespace=village-dev

# Méthode 2 — Via un fichier .env (non commité dans Git)
cat > /tmp/test.env << EOF
KEY1=valeur1
KEY2=valeur2
EOF
kubectl create secret generic test-secret-env \
  --from-env-file=/tmp/test.env \
  --namespace=village-dev

# Vérifier
kubectl get secrets -n village-dev

# Nettoyer les secrets de test
kubectl delete secret test-secret test-secret-env -n village-dev
```

### Étape 4.5 — Vérifier les Resource Limits

```bash
# Voir les limites CPU/Mémoire dans le Deployment frontend
kubectl describe deployment village-frontend -n village-dev | grep -A 10 "Limits\|Requests"

# Voir la consommation réelle des pods
kubectl top pods -n village-dev
# (nécessite metrics-server, voir LAB 08)

# Voir les limites par conteneur
kubectl get pods -n village-dev -l app=village-frontend \
  -o jsonpath='{.items[0].spec.containers[0].resources}' | python3 -m json.tool
```

### ✅ Vérification LAB 04

```bash
kubectl get configmaps -n village-dev
# → backend-config    ...
# → frontend-config   ...

kubectl get secrets -n village-dev
# → backend-secret   Opaque   2   ...

# Vérifier qu'un pod utilise bien les variables du ConfigMap
kubectl exec -n village-dev \
  $(kubectl get pod -n village-dev -l app=village-frontend -o jsonpath='{.items[0].metadata.name}') \
  -- env | grep -E "API_URL|ENVIRONMENT|APP_TITLE"
```

> 💡 **Ce que tu viens d'apprendre :** Les ConfigMaps stockent la configuration non-sensible et les Secrets stockent les données sensibles (mots de passe, clés). Les deux sont injectés dans les pods en tant que variables d'environnement ou fichiers montés.

---

## LAB 05 — Networking & Ingress

> **CKA :** Section "Services & Networking" — Services, Ingress, DNS, NetworkPolicies  
> **Objectif :** Exposer l'application à l'extérieur du cluster et sécuriser les communications réseau.

### 🎯 Objectifs du LAB

- Comprendre les types de Services (ClusterIP, NodePort, LoadBalancer)
- Configurer l'Ingress Controller Nginx
- Créer des règles de routage HTTP
- Appliquer des NetworkPolicies

### Étape 5.1 — Types de Services

```bash
# Services actuels (type ClusterIP — accès interne uniquement)
kubectl get services -n village-dev -o wide

# Voir le détail du Service frontend
cat k8s/frontend/service.yaml

# Créer temporairement un Service NodePort pour accès externe
kubectl expose deployment village-frontend \
  --name=village-frontend-nodeport \
  --type=NodePort \
  --port=80 \
  --target-port=80 \
  --namespace=village-dev

# Voir le port assigné (entre 30000-32767)
kubectl get service village-frontend-nodeport -n village-dev
# → village-frontend-nodeport   NodePort   10.x.x.x   80:3xxxx/TCP

# Accéder via Minikube
minikube service village-frontend-nodeport -n village-dev --url
# → http://127.0.0.1:3xxxx

# Nettoyer le Service NodePort temporaire
kubectl delete service village-frontend-nodeport -n village-dev
```

### Étape 5.2 — Activer l'Ingress Controller

```bash
# Activer l'addon Ingress sur Minikube
minikube addons enable ingress

# Vérifier que l'ingress controller est déployé
kubectl get pods -n ingress-nginx
# → ingress-nginx-controller-xxxxx   Running

# Voir les addons disponibles
minikube addons list | grep ingress
```

### Étape 5.3 — Déployer l'Ingress

```bash
# Voir le manifeste Ingress
cat k8s/ingress/ingress.yaml

# Appliquer l'Ingress
kubectl apply -f k8s/ingress/ingress.yaml

# Vérifier
kubectl get ingress -n village-dev
# → village-ingress   nginx   village.local   192.168.x.x   80   ...

# Voir les règles de routage
kubectl describe ingress village-ingress -n village-dev
```

### Étape 5.4 — Configurer /etc/hosts et tester

```bash
# Obtenir l'IP de Minikube
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Ajouter l'entrée DNS locale (nécessite sudo)
echo "$MINIKUBE_IP village.local" | sudo tee -a /etc/hosts

# Tester le routing Ingress
curl -s http://village.local/ | head -3
# → <!doctype html><html ...   (frontend Angular)

curl -s http://village.local/api/actuator/health
# → {"status":"UP"}            (backend Spring Boot)
```

### Étape 5.5 — Appliquer les NetworkPolicies

```bash
# Voir les politiques réseau
cat k8s/security/networkpolicy.yaml

# Appliquer les NetworkPolicies
kubectl apply -f k8s/security/networkpolicy.yaml

# Vérifier les NetworkPolicies créées
kubectl get networkpolicies -n village-dev
# → backend-allow-frontend-only   ...
# → frontend-allow-ingress        ...
# → postgres-allow-backend-only   ...

# Décrire une politique
kubectl describe networkpolicy backend-allow-frontend-only -n village-dev
```

### Étape 5.6 — Tester les NetworkPolicies

```bash
# Ce test doit RÉUSSIR (frontend → backend autorisé)
kubectl run test-frontend --image=busybox \
  --labels="app=village-frontend" \
  --restart=Never -n village-dev -- \
  wget -qO- --timeout=5 http://village-backend-svc:8080/actuator/health
# → {"status":"UP"}

# Ce test doit ÉCHOUER (pod sans label → backend refusé)
kubectl run test-unauthorized --image=busybox \
  --restart=Never -n village-dev -- \
  wget -qO- --timeout=5 http://village-backend-svc:8080/actuator/health
# → wget: download timed out (accès refusé par NetworkPolicy)

# Nettoyer les pods de test
kubectl delete pod test-frontend test-unauthorized -n village-dev
```

### ✅ Vérification LAB 05

```bash
kubectl get ingress -n village-dev
# → village-ingress   nginx   village.local   ...   80   ...

kubectl get networkpolicies -n village-dev
# → 3 NetworkPolicies listées

curl -s http://village.local/ | grep -i "village\|angular"
```

> 💡 **Ce que tu viens d'apprendre :** L'Ingress est un reverse-proxy K8s qui route le trafic HTTP/HTTPS vers les Services internes. Les NetworkPolicies sont le "firewall" de Kubernetes — par défaut tout est permis, mais dès qu'une politique est appliquée, seul le trafic explicitement autorisé passe.

---

## LAB 06 — Storage : PersistentVolume & PVC

> **CKA :** Section "Storage" — PV, PVC, StorageClasses  
> **Objectif :** Persister les données de la base de données PostgreSQL sur disque.

### 🎯 Objectifs du LAB

- Comprendre la différence entre PV et PVC
- Créer un PersistentVolume (stockage physique)
- Créer un PersistentVolumeClaim (demande de stockage)
- Déployer PostgreSQL avec stockage persistant

### Étape 6.1 — Comprendre PV vs PVC

```
PersistentVolume (PV)   = le disque physique (créé par l'admin)
PersistentVolumeClaim   = la demande de disque (créée par l'app)
StorageClass            = le type de disque (provisionnement dynamique)
```

```bash
# Voir les StorageClasses disponibles (Minikube en fournit une par défaut)
kubectl get storageclasses
# → standard   k8s.io/minikube-hostpath   Delete   Immediate   false   ...
```

### Étape 6.2 — Créer le PersistentVolume

```bash
# Voir le manifeste PV
cat k8s/storage/pv.yaml

# Créer le répertoire hôte nécessaire dans Minikube
minikube ssh -- sudo mkdir -p /mnt/data/village-postgres
minikube ssh -- sudo chmod 777 /mnt/data/village-postgres

# Appliquer le PV
kubectl apply -f k8s/storage/pv.yaml

# Vérifier le PV (status: Available)
kubectl get persistentvolumes
# → village-postgres-pv   5Gi   RWO   Retain   Available   manual   ...
```

### Étape 6.3 — Créer le PersistentVolumeClaim

```bash
# Voir le manifeste PVC
cat k8s/storage/pvc.yaml

# Appliquer le PVC
kubectl apply -f k8s/storage/pvc.yaml

# Vérifier le PVC (status: Bound — lié au PV)
kubectl get persistentvolumeclaims -n village-dev
# → village-postgres-pvc   Bound   village-postgres-pv   5Gi   RWO   manual   ...

# Vérifier que le PV est maintenant Bound
kubectl get persistentvolumes
# → village-postgres-pv   5Gi   RWO   Retain   Bound   village-dev/village-postgres-pvc   ...
```

### Étape 6.4 — Déployer PostgreSQL avec PVC

```bash
# Créer le Deployment PostgreSQL avec le PVC
cat > /tmp/postgres-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: village-dev
  labels:
    app: postgres
    project: village
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
        project: village
    spec:
      containers:
        - name: postgres
          image: postgres:15-alpine
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: "villagedb"
            - name: POSTGRES_USER
              value: "village"
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: backend-secret
                  key: DB_PASSWORD
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: village-postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-svc
  namespace: village-dev
  labels:
    app: postgres
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
EOF

kubectl apply -f /tmp/postgres-deployment.yaml

# Attendre que PostgreSQL démarre
kubectl rollout status deployment/postgres -n village-dev --timeout=120s
```

### Étape 6.5 — Tester la persistance des données

```bash
# Se connecter à PostgreSQL et créer des données
kubectl exec -n village-dev \
  $(kubectl get pod -n village-dev -l app=postgres -o jsonpath='{.items[0].metadata.name}') \
  -- psql -U village -d villagedb -c \
  "CREATE TABLE test_persistence (id SERIAL PRIMARY KEY, data TEXT); INSERT INTO test_persistence (data) VALUES ('données persistantes');"

# Vérifier les données
kubectl exec -n village-dev \
  $(kubectl get pod -n village-dev -l app=postgres -o jsonpath='{.items[0].metadata.name}') \
  -- psql -U village -d villagedb -c "SELECT * FROM test_persistence;"

# Supprimer le pod (il sera recréé par le Deployment)
kubectl delete pod -n village-dev -l app=postgres
kubectl rollout status deployment/postgres -n village-dev --timeout=120s

# Vérifier que les données sont toujours là (grâce au PVC !)
kubectl exec -n village-dev \
  $(kubectl get pod -n village-dev -l app=postgres -o jsonpath='{.items[0].metadata.name}') \
  -- psql -U village -d villagedb -c "SELECT * FROM test_persistence;"
# → Les données sont toujours là 🎉
```

### ✅ Vérification LAB 06

```bash
kubectl get pv
# → village-postgres-pv   5Gi   RWO   Retain   Bound   village-dev/village-postgres-pvc

kubectl get pvc -n village-dev
# → village-postgres-pvc   Bound   village-postgres-pv   5Gi   RWO   manual

kubectl get pods -n village-dev -l app=postgres
# → postgres-xxxxx   1/1   Running   ...
```

> 💡 **Ce que tu viens d'apprendre :** Les données d'une base de données doivent être persistées sur un volume externe. Si le pod est détruit et recréé, les données restent intactes grâce au PVC lié au PV. En production, on utilise des StorageClasses dynamiques (AWS EBS, GCP Persistent Disk, etc.) au lieu de hostPath.

---

## LAB 07 — Sécurité : RBAC & ServiceAccounts

> **CKA :** Section "Security" — RBAC, ServiceAccounts, SecurityContext  
> **Objectif :** Appliquer le principe du moindre privilège sur le cluster.

### 🎯 Objectifs du LAB

- Créer des ServiceAccounts dédiés par microservice
- Définir des Roles et RoleBindings (RBAC)
- Comprendre le SecurityContext
- Tester les permissions RBAC

### Étape 7.1 — Explorer les ServiceAccounts

```bash
# Voir les manifestes ServiceAccount
cat k8s/security/serviceaccount.yaml

# Vérifier les ServiceAccounts créés (depuis LAB 03)
kubectl get serviceaccounts -n village-dev
# → default                1   ...
# → village-backend-sa     1   ...
# → village-frontend-sa    1   ...

# Voir les détails d'un ServiceAccount
kubectl describe serviceaccount village-backend-sa -n village-dev
```

### Étape 7.2 — Explorer les Roles et RoleBindings

```bash
# Voir le manifeste RBAC
cat k8s/security/rbac.yaml

# Vérifier les Roles créés
kubectl get roles -n village-dev
# → village-backend-role    ...
# → village-frontend-role   ...

# Voir les permissions du role backend
kubectl describe role village-backend-role -n village-dev
# → Ressources autorisées : configmaps (get,list,watch), secrets (get)

# Vérifier les RoleBindings
kubectl get rolebindings -n village-dev
kubectl describe rolebinding village-backend-rolebinding -n village-dev
```

### Étape 7.3 — Appliquer les manifestes RBAC

```bash
# Appliquer les RBAC
kubectl apply -f k8s/security/rbac.yaml

# Tester les permissions avec kubectl auth can-i
# Le backend PEUT lire les ConfigMaps
kubectl auth can-i get configmaps \
  --namespace=village-dev \
  --as=system:serviceaccount:village-dev:village-backend-sa
# → yes

# Le backend PEUT lire le secret backend-secret
kubectl auth can-i get secrets/backend-secret \
  --namespace=village-dev \
  --as=system:serviceaccount:village-dev:village-backend-sa
# → yes

# Le backend NE PEUT PAS supprimer des pods
kubectl auth can-i delete pods \
  --namespace=village-dev \
  --as=system:serviceaccount:village-dev:village-backend-sa
# → no

# Le frontend NE PEUT PAS accéder aux secrets
kubectl auth can-i get secrets \
  --namespace=village-dev \
  --as=system:serviceaccount:village-dev:village-frontend-sa
# → no
```

### Étape 7.4 — Comprendre le SecurityContext

```bash
# Voir le SecurityContext dans le Deployment backend
kubectl get deployment village-backend -n village-dev \
  -o jsonpath='{.spec.template.spec.securityContext}' | python3 -m json.tool
# → {"fsGroup": 1000, "runAsNonRoot": true, "runAsUser": 1000}

# Vérifier que le conteneur ne tourne pas en root
kubectl exec -n village-dev \
  $(kubectl get pod -n village-dev -l app=village-backend -o jsonpath='{.items[0].metadata.name}') \
  -- id
# → uid=1000(village) gid=1000(village) groups=1000(village)
# → PAS root (uid=0) !

# Essayer d'escalader les privilèges (doit échouer)
kubectl exec -n village-dev \
  $(kubectl get pod -n village-dev -l app=village-backend -o jsonpath='{.items[0].metadata.name}') \
  -- sh -c "whoami && id"
```

### Étape 7.5 — Créer un ClusterRole (exemple)

```bash
# Créer un ClusterRole en lecture seule sur tout le cluster
cat > /tmp/readonly-clusterrole.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: village-readonly
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "namespaces"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch"]
EOF

kubectl apply -f /tmp/readonly-clusterrole.yaml

# Voir les ClusterRoles créés
kubectl get clusterroles | grep village

# Nettoyer
kubectl delete clusterrole village-readonly
```

### ✅ Vérification LAB 07

```bash
# Vérifier les permissions du backend
kubectl auth can-i get configmaps \
  --namespace=village-dev \
  --as=system:serviceaccount:village-dev:village-backend-sa
# → yes

kubectl auth can-i delete deployments \
  --namespace=village-dev \
  --as=system:serviceaccount:village-dev:village-backend-sa
# → no

# Vérifier l'utilisateur dans le conteneur backend
kubectl exec -n village-dev deployment/village-backend -- id
# → uid=1000(village) ...
```

> 💡 **Ce que tu viens d'apprendre :** RBAC (Role-Based Access Control) est le système de permissions de Kubernetes. Chaque pod doit avoir son propre ServiceAccount avec uniquement les permissions nécessaires (principe du moindre privilège). Le SecurityContext empêche l'exécution en root.

---

## LAB 08 — Observabilité : Probes & HPA

> **CKA :** Section "Observability" — Liveness/Readiness Probes, Monitoring, Logging  
> **Objectif :** Monitorer l'application et configurer l'auto-scaling.

### 🎯 Objectifs du LAB

- Comprendre et tester les Liveness/Readiness/Startup Probes
- Installer le metrics-server
- Configurer le HorizontalPodAutoscaler (HPA)
- Analyser les logs des pods

### Étape 8.1 — Explorer les Probes

```bash
# Voir les probes dans le Deployment backend
kubectl get deployment village-backend -n village-dev -o yaml | \
  grep -A 20 "livenessProbe\|readinessProbe\|startupProbe"

# Voir les probes dans le Deployment frontend
kubectl get deployment village-frontend -n village-dev -o yaml | \
  grep -A 10 "livenessProbe\|readinessProbe"
```

Les 3 types de probes :
- **startupProbe** → Attendre que l'app démarre (désactive les autres le temps du démarrage)
- **livenessProbe** → L'app est-elle vivante ? (redémarre si KO)
- **readinessProbe** → L'app est-elle prête à recevoir du trafic ? (retire du Service si KO)

### Étape 8.2 — Observer les Probes en action

```bash
# Voir les événements d'un pod (inclut les échecs de probes)
kubectl describe pod -l app=village-backend -n village-dev | grep -A 5 "Events\|Probe"

# Voir le compteur de redémarrages (colonne RESTARTS)
kubectl get pods -n village-dev
# Si RESTARTS > 0, une probe a échoué et redémarré le conteneur

# Simuler un échec de probe (modifier temporairement le path de probe)
# Note: dans un vrai scénario, l'app qui plante déclenche la probe
kubectl get pod -l app=village-backend -n village-dev \
  -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}'
# → True (le pod est prêt)
```

### Étape 8.3 — Installer le metrics-server

```bash
# Activer le metrics-server sur Minikube
minikube addons enable metrics-server

# Attendre que le metrics-server soit prêt
kubectl rollout status deployment/metrics-server -n kube-system --timeout=120s

# Tester la collecte de métriques (attendre ~1 minute)
sleep 60
kubectl top nodes
# → NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# → minikube   ...

kubectl top pods -n village-dev
# → NAME                        CPU(cores)   MEMORY(bytes)
# → village-frontend-xxxxx      1m           20Mi
# → village-backend-xxxxx       5m           180Mi
```

### Étape 8.4 — Configurer le HPA

```bash
# Voir les manifestes HPA
cat k8s/frontend/hpa.yaml
cat k8s/backend/hpa.yaml

# Appliquer les HPA
kubectl apply -f k8s/frontend/hpa.yaml
kubectl apply -f k8s/backend/hpa.yaml

# Vérifier les HPA
kubectl get hpa -n village-dev
# → village-frontend-hpa   Deployment/village-frontend   cpu: 0%/70%   1/3   1   ...
# → village-backend-hpa    Deployment/village-backend    cpu: 0%/70%   1/3   1   ...

# Voir les détails du HPA
kubectl describe hpa village-frontend-hpa -n village-dev
```

### Étape 8.5 — Tester le HPA (charge CPU)

```bash
# Générer de la charge CPU sur le frontend
kubectl run load-generator \
  --image=busybox \
  --restart=Never \
  -n village-dev \
  -- sh -c "while true; do wget -qO- http://village-frontend-svc:80 > /dev/null; done"

# Observer le HPA scaler (dans un autre terminal)
kubectl get hpa village-frontend-hpa -n village-dev -w
# → Après quelques minutes, REPLICAS va augmenter automatiquement

# Observer les pods se créer
kubectl get pods -n village-dev -w

# Arrêter le générateur de charge
kubectl delete pod load-generator -n village-dev

# Observer le HPA réduire les replicas (après ~2 minutes)
kubectl get hpa village-frontend-hpa -n village-dev -w
```

### Étape 8.6 — Analyser les Logs

```bash
# Logs en temps réel du backend
kubectl logs -f deployment/village-backend -n village-dev

# Logs des 100 dernières lignes
kubectl logs --tail=100 deployment/village-frontend -n village-dev

# Logs avec timestamps
kubectl logs --timestamps deployment/village-backend -n village-dev | tail -20

# Logs de tous les pods avec le label app=village-backend
kubectl logs -l app=village-backend -n village-dev --all-containers

# Logs du pod précédent (après un crash/redémarrage)
kubectl logs -l app=village-backend -n village-dev --previous
```

### ✅ Vérification LAB 08

```bash
# Métriques disponibles
kubectl top pods -n village-dev

# HPA configuré et actif
kubectl get hpa -n village-dev
# → TARGETS: cpu: X%/70%, memory: X%/80%

# Probes actives et OK
kubectl get pods -n village-dev
# → RESTARTS: 0 (aucun redémarrage = probes OK)
```

> 💡 **Ce que tu viens d'apprendre :** Les Probes permettent à Kubernetes de détecter automatiquement les pannes et redémarrer les pods. Le HPA ajuste automatiquement le nombre de replicas en fonction de la charge CPU/mémoire. Les logs `kubectl logs` sont l'outil de base pour debugger les applications.

---

## LAB 09 — CI/CD : GitHub Actions

> **CKA :** Maîtrise des outils DevOps complémentaires  
> **Objectif :** Automatiser le build, les tests et la publication des images Docker.

### 🎯 Objectifs du LAB

- Comprendre la structure d'un workflow GitHub Actions
- Configurer les secrets GitHub
- Analyser le pipeline CI (build + test + push)
- Déclencher le pipeline et observer l'exécution

### Étape 9.1 — Explorer les workflows existants

```bash
# Voir tous les workflows
ls .github/workflows/
# → ci-build.yml
# → cd-dev.yml
# → cd-prod.yml

# Lire le workflow CI
cat .github/workflows/ci-build.yml
```

Le workflow `ci-build.yml` contient 3 jobs :
1. `build-frontend` → Build Angular + Docker
2. `build-backend` → Build Maven + Docker
3. `validate-k8s-manifests` → Validation YAML avec kubectl dry-run

### Étape 9.2 — Configurer les secrets GitHub

Dans l'interface GitHub de ton repository :
1. Aller dans **Settings → Secrets and variables → Actions**
2. Cliquer **New repository secret**
3. Ajouter les secrets suivants :

| Nom du secret | Description | Valeur |
|---------------|-------------|--------|
| `KUBECONFIG` | Contenu du fichier kubeconfig | `$(cat ~/.kube/config \| base64)` |
| `DB_PASSWORD` | Mot de passe PostgreSQL | `village123` |
| `JWT_SECRET` | Clé secrète JWT | `your-secret-key-min-32-chars` |

```bash
# Générer le contenu encodé du kubeconfig pour le secret GitHub
cat ~/.kube/config | base64 | tr -d '\n'
# → Copier cette valeur dans le secret KUBECONFIG sur GitHub
```

### Étape 9.3 — Analyser le job de build frontend

```bash
# Voir la configuration du build frontend dans le workflow
grep -A 40 "build-frontend:" .github/workflows/ci-build.yml
```

Étapes du job `build-frontend` :
1. `checkout` → Cloner le repo DevOps
2. `checkout village` → Cloner le code source Angular
3. `setup-node` → Installer Node.js 18
4. `npm ci` → Installer les dépendances
5. `npm run lint` → Vérifier la qualité du code
6. `npm run build` → Compiler Angular
7. `docker build-push-action` → Build image Docker (sans push en CI)

### Étape 9.4 — Tester la validation des manifestes localement

```bash
# Simuler ce que fait le job validate-k8s-manifests
# (dry-run = valide le YAML sans créer les ressources)

kubectl apply -f k8s/namespace/ --dry-run=client
kubectl apply -f k8s/security/serviceaccount.yaml --dry-run=client -n village-dev
kubectl apply -f k8s/security/rbac.yaml --dry-run=client -n village-dev
kubectl apply -f k8s/backend/configmap.yaml --dry-run=client
kubectl apply -f k8s/frontend/configmap.yaml --dry-run=client
kubectl apply -f k8s/backend/deployment.yaml --dry-run=client
kubectl apply -f k8s/frontend/deployment.yaml --dry-run=client
kubectl apply -f k8s/ingress/ingress.yaml --dry-run=client

echo "✅ Tous les manifestes sont valides !"
```

### Étape 9.5 — Déclencher le pipeline CI

```bash
# Créer une branche de test et faire un commit
git checkout -b test/ci-trigger
echo "# Test CI trigger" >> /tmp/test-file.md
cp /tmp/test-file.md test-ci.md
git add test-ci.md
git commit -m "test: trigger CI pipeline"
git push origin test/ci-trigger

# Créer une Pull Request sur GitHub vers la branche develop ou main
# → Le workflow ci-build.yml se déclenchera automatiquement

# Puis nettoyer
git checkout main
git branch -d test/ci-trigger
git push origin --delete test/ci-trigger
rm test-ci.md
git add -A && git commit -m "chore: cleanup test" || true
```

### Étape 9.6 — Lire le workflow CD

```bash
# Voir le workflow de déploiement DEV
cat .github/workflows/cd-dev.yml

# Points importants :
# - Déclenché sur push vers 'develop'
# - Utilise le secret KUBECONFIG pour se connecter au cluster
# - Fait un 'kubectl set image' pour mettre à jour l'image
# - Attend le rollout avec 'kubectl rollout status'
```

### ✅ Vérification LAB 09

- Dans l'onglet **Actions** de GitHub, le workflow CI doit apparaître
- Les 3 jobs doivent passer au vert ✅
- Les images Docker ne sont pas pushées en CI (push: false) — seulement validées

> 💡 **Ce que tu viens d'apprendre :** Un pipeline CI/CD automatise le build, les tests et le déploiement. GitHub Actions utilise des fichiers YAML pour définir les workflows déclenchés sur des événements Git (push, PR). Le `dry-run` de kubectl permet de valider les manifestes sans les appliquer.

---

## LAB 10 — Déploiement automatique DEV / PROD

> **CKA :** Section "Cluster Maintenance" — Rolling Updates, Rollbacks  
> **Objectif :** Déployer et mettre à jour l'application sur deux environnements avec stratégie de rollback.

### 🎯 Objectifs du LAB

- Utiliser le script de déploiement DEV
- Effectuer un Rolling Update
- Tester le Rollback
- Comprendre la différence DEV / PROD

### Étape 10.1 — Déploiement DEV complet avec le script

```bash
# Voir le script de déploiement DEV
cat scripts/deploy-dev.sh

# Rendre le script exécutable
chmod +x scripts/deploy-dev.sh
chmod +x scripts/deploy-prod.sh
chmod +x scripts/setup-cluster.sh

# Lancer le déploiement DEV
# (il demandera les mots de passe si les secrets n'existent pas)
DB_PASSWORD="village123" JWT_SECRET="village-jwt-secret-change-in-prod" \
  ./scripts/deploy-dev.sh

# Observer le résumé final
# → URLs d'accès listées
# → kubectl get all -n village-dev affiché
```

### Étape 10.2 — Rolling Update manuellement

```bash
# Voir l'historique des déploiements
kubectl rollout history deployment/village-frontend -n village-dev
# → REVISION   CHANGE-CAUSE
# → 1          Initial deployment

# Simuler une mise à jour d'image (comme un nouveau déploiement CI/CD)
kubectl set image deployment/village-frontend \
  frontend=ghcr.io/abdenourdjouder/village-frontend:v2.0.0 \
  --namespace=village-dev \
  --record

# Observer le Rolling Update en temps réel
kubectl rollout status deployment/village-frontend -n village-dev

# Observer les pods pendant le rolling update
kubectl get pods -n village-dev -w
# → Un nouveau pod est créé AVANT que l'ancien soit supprimé (maxSurge: 1)

# Voir le nouvel historique
kubectl rollout history deployment/village-frontend -n village-dev
# → REVISION   CHANGE-CAUSE
# → 1          Initial deployment
# → 2          kubectl set image deployment/village-frontend ...
```

### Étape 10.3 — Rollback

```bash
# Simuler un problème avec la nouvelle version
# (image inexistante → pods en état ImagePullBackOff)
kubectl set image deployment/village-frontend \
  frontend=ghcr.io/abdenourdjouder/village-frontend:broken-version \
  --namespace=village-dev

# Voir les pods en erreur
kubectl get pods -n village-dev
# → village-frontend-xxxxx   0/1   ImagePullBackOff   0   ...

# Voir les événements d'erreur
kubectl describe pod -l app=village-frontend -n village-dev | grep -A 5 "Events"
# → Failed to pull image ...

# ROLLBACK vers la version précédente
kubectl rollout undo deployment/village-frontend -n village-dev

# Suivre le rollback
kubectl rollout status deployment/village-frontend -n village-dev

# Vérifier que l'app fonctionne de nouveau
kubectl get pods -n village-dev -l app=village-frontend
# → 1/1 Running

# Rollback vers une révision spécifique
kubectl rollout undo deployment/village-frontend \
  --to-revision=1 \
  -n village-dev
```

### Étape 10.4 — Comparer DEV vs PROD

```bash
# Namespace PROD
kubectl apply -f k8s/namespace/prod-namespace.yaml

# En PROD, on déploie avec plus de replicas
cat > /tmp/patch-prod-replicas.yaml << 'EOF'
spec:
  replicas: 2
EOF

# Créer les ressources PROD (exemple simplifié)
# En vrai, on utiliserait Helm ou Kustomize pour gérer les différences DEV/PROD

# Voir la différence de replicas
kubectl get deployments -n village-dev
# → village-frontend   1/1   replicas: 1

# En prod ce serait
# → village-frontend   2/2   replicas: 2
```

### Étape 10.5 — Vérification finale de tout le projet

```bash
# Vue complète du namespace DEV
kubectl get all -n village-dev

# Ressources de sécurité
kubectl get serviceaccounts,roles,rolebindings,networkpolicies -n village-dev

# Stockage
kubectl get pv,pvc -n village-dev

# HPA
kubectl get hpa -n village-dev

# Ingress
kubectl get ingress -n village-dev

# Accéder à l'application
echo "Frontend: http://village.local"
echo "Backend:  http://village.local/api/actuator/health"
curl -s http://village.local/api/actuator/health | python3 -m json.tool
```

### Étape 10.6 — Nettoyage complet (reset du LAB)

```bash
# Supprimer tous les déploiements du namespace DEV
kubectl delete namespace village-dev

# Supprimer les PV (les données sont supprimées)
kubectl delete persistentvolume village-postgres-pv

# Supprimer les entrées /etc/hosts
sudo sed -i '/village.local/d' /etc/hosts

# Réinitialiser Minikube (option nucléaire — repart de zéro)
# minikube delete
# minikube start --cpus=2 --memory=4096 --driver=docker
```

### ✅ Vérification finale du projet

```bash
# Tout le projet fonctionnel en une commande
kubectl get all,ingress,pvc,hpa,networkpolicies,roles,rolebindings,serviceaccounts \
  -n village-dev

# L'application répond
curl -s http://village.local/ | grep -i "village" && echo "✅ Frontend OK"
curl -s http://village.local/api/actuator/health | grep -i "UP" && echo "✅ Backend OK"
```

> 💡 **Ce que tu viens d'apprendre :** Le Rolling Update déploie la nouvelle version progressivement, sans downtime. Le Rollback revient à la version précédente en quelques secondes. En production, on utilise des namespaces séparés avec des ressources différentes (plus de replicas, ressources plus importantes) pour isoler les environnements DEV et PROD.

---

## 🚀 Récapitulatif — Commandes essentielles

### kubectl — Commandes les plus utilisées

```bash
# ──── Inspection ────────────────────────────────────────
kubectl get all -n <namespace>                    # Tout voir
kubectl get pods -n <namespace> -w               # Watch en temps réel
kubectl describe pod <pod> -n <namespace>         # Détails d'un pod
kubectl logs -f <pod> -n <namespace>              # Logs en temps réel
kubectl exec -it <pod> -n <namespace> -- sh      # Shell dans un pod

# ──── Déploiement ────────────────────────────────────────
kubectl apply -f <fichier.yaml>                   # Créer/mettre à jour
kubectl delete -f <fichier.yaml>                  # Supprimer
kubectl rollout status deployment/<name> -n <ns>  # Suivre un rollout
kubectl rollout undo deployment/<name> -n <ns>    # Rollback
kubectl set image deployment/<name> <c>=<image>   # Changer l'image

# ──── Debugging ──────────────────────────────────────────
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl top pods -n <namespace>                   # Consommation ressources
kubectl port-forward pod/<pod> 8080:8080          # Redirection de port
kubectl auth can-i <verb> <resource> --as=<sa>   # Tester les permissions

# ──── Configuration ──────────────────────────────────────
kubectl create configmap <name> --from-literal=k=v
kubectl create secret generic <name> --from-literal=k=v
kubectl get configmap <name> -o yaml              # Voir le YAML complet
```

### Architecture finale du cluster

```
Cluster Minikube
└── Namespace: village-dev
    ├── Deployments
    │   ├── village-frontend  (Angular/Nginx, replicas: 1-3)
    │   ├── village-backend   (Spring Boot, replicas: 1-3)
    │   └── postgres          (PostgreSQL, replicas: 1)
    ├── Services
    │   ├── village-frontend-svc (ClusterIP:80)
    │   ├── village-backend-svc  (ClusterIP:8080)
    │   └── postgres-svc         (ClusterIP:5432)
    ├── Ingress
    │   └── village-ingress  (village.local → frontend/backend)
    ├── Storage
    │   └── village-postgres-pvc → village-postgres-pv (5Gi)
    ├── Configuration
    │   ├── ConfigMap: frontend-config
    │   ├── ConfigMap: backend-config
    │   └── Secret:    backend-secret
    ├── Security
    │   ├── ServiceAccount: village-frontend-sa
    │   ├── ServiceAccount: village-backend-sa
    │   ├── Role/RoleBinding: village-frontend-role
    │   ├── Role/RoleBinding: village-backend-role
    │   └── NetworkPolicies: 3 politiques
    └── Autoscaling
        ├── HPA: village-frontend-hpa (1-3 replicas)
        └── HPA: village-backend-hpa  (1-3 replicas)
```

---

## 📚 Ressources pour aller plus loin

| Ressource | Description | Lien |
|-----------|-------------|------|
| **KodeKloud CKA** | Cours officiel de préparation CKA | https://learn.kodekloud.com/user/courses/cka-certification-course-certified-kubernetes-administrator |
| **Kubernetes Docs** | Documentation officielle | https://kubernetes.io/docs/ |
| **Play with K8s** | Cluster K8s gratuit en ligne | https://labs.play-with-k8s.com/ |
| **Killer.sh** | Simulateur d'examen CKA | https://killer.sh/ |
| **Application Village** | Code source Angular + Spring Boot | https://github.com/abdenourdjouder/village |
| **Helm** | Gestionnaire de packages K8s | https://helm.sh/ |
| **Kustomize** | Gestion des configurations multi-env | https://kustomize.io/ |

---

*Guide réalisé par [abdenourdjouder](https://github.com/abdenourdjouder) — Portfolio Kubernetes & DevOps*

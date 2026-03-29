# Étape 06 — Storage

> **Branche :** `step-06/k8s-storage`
> **CKA Section :** Storage (10% de l'examen)

---

## 🎯 Objectif CKA

Maîtriser la persistance des données dans Kubernetes :
- **PersistentVolume (PV)** : ressource de stockage dans le cluster
- **PersistentVolumeClaim (PVC)** : demande de stockage par un pod
- **StorageClass** : provisionnement dynamique de stockage
- **Volumes** : types de volumes (emptyDir, hostPath, configMap, secret)

---

## 📋 Tâches de cette étape

- [ ] Créer un **PersistentVolume** pour la base de données
- [ ] Créer un **PersistentVolumeClaim** pour le pod PostgreSQL
- [ ] Déployer **PostgreSQL** avec stockage persistant
- [ ] Tester la persistance des données après redémarrage du pod
- [ ] Configurer une **StorageClass** pour le provisionnement dynamique

---

## 📐 Architecture de stockage

```
┌─────────────────────────────────────────────────────────────┐
│                    Storage Architecture                      │
│                                                             │
│  PersistentVolume (PV)           PersistentVolumeClaim (PVC)│
│  ┌───────────────────────┐       ┌────────────────────────┐ │
│  │  Capacité: 5Gi        │◄─────▶│  Requête: 5Gi          │ │
│  │  AccessMode: RWO      │ Bound │  AccessMode: RWO       │ │
│  │  StorageClass: manual │       │  StorageClass: manual  │ │
│  └───────────────────────┘       └────────────────────────┘ │
│               │                               │              │
│               └───────────────────────────────┘              │
│                               │                              │
│                               ▼                              │
│                  ┌────────────────────────┐                  │
│                  │  PostgreSQL Pod        │                  │
│                  │  volumeMount:          │                  │
│                  │    /var/lib/postgresql │                  │
│                  └────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📐 Manifestes Kubernetes (Storage)

### PersistentVolume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: village-postgres-pv
  labels:
    type: local
    app: postgres
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data/village-postgres"
```

### PersistentVolumeClaim
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: village-postgres-pvc
  namespace: village-dev
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

### Déploiement PostgreSQL
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: village-postgres
  namespace: village-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15-alpine
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: villagedb
            - name: POSTGRES_USER
              value: village
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: backend-secret
                  key: DB_PASSWORD
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgres-storage
              subPath: postgres
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: village-postgres-pvc
```

---

## 🔧 Commandes kubectl (Storage)

```bash
# Appliquer PV et PVC
kubectl apply -f k8s/storage/pv.yaml
kubectl apply -f k8s/storage/pvc.yaml

# Vérifier le statut du PV
kubectl get pv

# Vérifier le statut du PVC
kubectl get pvc -n village-dev

# Voir les détails d'un PVC
kubectl describe pvc village-postgres-pvc -n village-dev

# Vérifier que le PVC est en état "Bound"
kubectl get pvc -n village-dev -o wide

# Lister les StorageClasses disponibles
kubectl get storageclass

# Se connecter à PostgreSQL pour tester
kubectl exec -it <postgres-pod> -n village-dev -- psql -U village -d villagedb

# Tester la persistance (créer des données, supprimer le pod, vérifier)
kubectl delete pod <postgres-pod> -n village-dev
kubectl get pods -n village-dev  # Un nouveau pod sera créé
```

---

## ✅ Critères de validation

- [ ] PV créé avec `kubectl get pv`
- [ ] PVC en état `Bound` avec `kubectl get pvc -n village-dev`
- [ ] PostgreSQL déployé et accessible
- [ ] Données persistantes après suppression et recréation du pod
- [ ] Backend Spring Boot connecté à la base de données

---

## 🔗 Ressources

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [KodeKloud CKA — Storage](https://learn.kodekloud.com/user/courses/cka-certification-course-certified-kubernetes-administrator)

---

*Étape précédente → [Étape 05 — Networking](step-05-k8s-networking.md)*
*Prochaine étape → [Étape 07 — Security](step-07-k8s-security.md)*

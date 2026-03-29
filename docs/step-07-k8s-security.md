# Étape 07 — Security

> **Branche :** `step-07/k8s-security`
> **CKA Section :** Security (12% de l'examen)

---

## 🎯 Objectif CKA

Maîtriser la sécurité dans Kubernetes :
- **RBAC** : Role-Based Access Control (qui peut faire quoi)
- **ServiceAccount** : identité des pods dans le cluster
- **SecurityContext** : définir les droits d'exécution d'un conteneur
- **Admission Controllers** : contrôle des requêtes API
- **TLS Certificates** : communication sécurisée

---

## 📋 Tâches de cette étape

- [ ] Créer des **ServiceAccounts** dédiés pour frontend et backend
- [ ] Créer des **Roles** et **RoleBindings** (RBAC namespace-scoped)
- [ ] Créer des **ClusterRoles** et **ClusterRoleBindings** (RBAC cluster-scoped)
- [ ] Ajouter des **SecurityContext** aux pods
- [ ] Appliquer les **NetworkPolicies** (déplacées depuis étape 05)

---

## 📐 Architecture RBAC

```
┌─────────────────────────────────────────────────────────────┐
│                    RBAC Architecture                         │
│                                                             │
│  Subject (qui ?)          Role (quoi ?)                      │
│  ┌──────────────────┐     ┌────────────────────────────────┐ │
│  │  ServiceAccount  │     │  Role (namespace-scoped)       │ │
│  │  (backend-sa)    │     │  - get pods                    │ │
│  └──────────────────┘     │  - list services               │ │
│           │               └────────────────────────────────┘ │
│           │  RoleBinding                    │                │
│           └─────────────────────────────────┘                │
│                                                             │
│  Subject (qui ?)          ClusterRole (quoi ?)               │
│  ┌──────────────────┐     ┌────────────────────────────────┐ │
│  │  ServiceAccount  │     │  ClusterRole (cluster-scoped)  │ │
│  │  (cicd-sa)       │     │  - get/list/watch nodes        │ │
│  └──────────────────┘     │  - get/list namespaces         │ │
│           │               └────────────────────────────────┘ │
│           │  ClusterRoleBinding             │                │
│           └─────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

---

## 📐 Manifestes Kubernetes (Security)

### ServiceAccount
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: village-backend-sa
  namespace: village-dev
  labels:
    app: village-backend
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: village-frontend-sa
  namespace: village-dev
  labels:
    app: village-frontend
```

### Role (namespace-scoped)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: village-backend-role
  namespace: village-dev
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]
```

### RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: village-backend-rolebinding
  namespace: village-dev
subjects:
  - kind: ServiceAccount
    name: village-backend-sa
    namespace: village-dev
roleRef:
  kind: Role
  name: village-backend-role
  apiGroup: rbac.authorization.k8s.io
```

### SecurityContext
```yaml
# Dans un Deployment
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
        - name: backend
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
```

---

## 🔧 Commandes kubectl (Security)

```bash
# Appliquer RBAC et ServiceAccounts
kubectl apply -f k8s/security/serviceaccount.yaml
kubectl apply -f k8s/security/rbac.yaml

# Lister les ServiceAccounts
kubectl get serviceaccounts -n village-dev

# Lister les Roles
kubectl get roles -n village-dev
kubectl get clusterroles | grep village

# Vérifier les permissions d'un ServiceAccount
kubectl auth can-i get pods --as=system:serviceaccount:village-dev:village-backend-sa -n village-dev
kubectl auth can-i delete pods --as=system:serviceaccount:village-dev:village-backend-sa -n village-dev

# Voir les RoleBindings
kubectl get rolebindings -n village-dev
kubectl describe rolebinding village-backend-rolebinding -n village-dev

# Vérifier le SecurityContext d'un pod
kubectl get pod <pod-name> -n village-dev -o jsonpath='{.spec.securityContext}'

# Lister les NetworkPolicies
kubectl get networkpolicies -n village-dev
```

---

## ✅ Critères de validation

- [ ] ServiceAccounts créés pour frontend et backend
- [ ] Roles et RoleBindings appliqués
- [ ] Permissions vérifiées avec `kubectl auth can-i`
- [ ] SecurityContext configuré (non-root, readOnly filesystem)
- [ ] NetworkPolicies limitant le trafic inter-pods

---

## 🔗 Ressources

- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [ServiceAccounts](https://kubernetes.io/docs/concepts/security/service-accounts/)
- [SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [NetworkPolicies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [KodeKloud CKA — Security](https://learn.kodekloud.com/user/courses/cka-certification-course-certified-kubernetes-administrator)

---

*Étape précédente → [Étape 06 — Storage](step-06-k8s-storage.md)*
*Prochaine étape → [Étape 08 — Observabilité](step-08-k8s-observability.md)*

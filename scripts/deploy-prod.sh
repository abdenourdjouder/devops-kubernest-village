#!/usr/bin/env bash
# ============================================================
# Script de déploiement PROD
# Déploie l'application Village dans le namespace village-prod
# Usage: ./scripts/deploy-prod.sh <version>
# Exemple: ./scripts/deploy-prod.sh v1.2.3
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

NAMESPACE="village-prod"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(dirname "$SCRIPT_DIR")/k8s"

REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_NAMESPACE="${IMAGE_NAMESPACE:-abdenourdjouder}"

# ──────────────────────────────────────────────────────────
# Valider les arguments
# ──────────────────────────────────────────────────────────
validate_args() {
  if [ $# -lt 1 ]; then
    log_error "Usage: $0 <version>"
    log_error "Exemple: $0 v1.2.3"
    exit 1
  fi
  
  VERSION="$1"
  
  if ! echo "$VERSION" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
    log_error "Format de version invalide: $VERSION"
    log_error "Utiliser le format: vX.Y.Z (ex: v1.2.3)"
    exit 1
  fi
  
  log_info "Version à déployer: $VERSION"
}

# ──────────────────────────────────────────────────────────
# Confirmation avant déploiement PROD
# ──────────────────────────────────────────────────────────
confirm_deployment() {
  echo ""
  log_warning "⚠️  Vous êtes sur le point de déployer en PRODUCTION !"
  log_warning "    Namespace   : $NAMESPACE"
  log_warning "    Version     : $VERSION"
  log_warning "    Registry    : ${REGISTRY}/${IMAGE_NAMESPACE}"
  echo ""
  read -rp "Confirmer le déploiement PROD ? (tapez 'yes' pour confirmer): " CONFIRM
  
  if [ "$CONFIRM" != "yes" ]; then
    log_info "Déploiement annulé."
    exit 0
  fi
}

# ──────────────────────────────────────────────────────────
# Vérifier la connexion
# ──────────────────────────────────────────────────────────
check_cluster() {
  log_info "Vérification de la connexion au cluster PROD..."
  kubectl cluster-info &>/dev/null || { log_error "Impossible de se connecter au cluster K8s"; exit 1; }
  log_info "✅ Cluster accessible."
}

# ──────────────────────────────────────────────────────────
# Déploiement PROD
# ──────────────────────────────────────────────────────────
deploy_prod() {
  log_info "=== Déploiement PROD (${NAMESPACE}) — ${VERSION} ==="
  
  # 1. Namespace PROD
  log_info "1/8 Namespace PROD..."
  kubectl apply -f "$K8S_DIR/namespace/prod-namespace.yaml"
  
  # 2. ServiceAccounts & RBAC (adaptés pour PROD)
  log_info "2/8 ServiceAccounts & RBAC..."
  sed 's/namespace: village-dev/namespace: village-prod/g' "$K8S_DIR/security/serviceaccount.yaml" | kubectl apply -f -
  sed 's/namespace: village-dev/namespace: village-prod/g' "$K8S_DIR/security/rbac.yaml" | kubectl apply -f -
  
  # 3. ConfigMaps PROD
  log_info "3/8 ConfigMaps PROD..."
  sed 's/namespace: village-dev/namespace: village-prod/g; s/ENVIRONMENT: "dev"/ENVIRONMENT: "prod"/g; s/SPRING_PROFILES_ACTIVE: "dev"/SPRING_PROFILES_ACTIVE: "prod"/g' \
    "$K8S_DIR/backend/configmap.yaml" | kubectl apply -f -
  sed 's/namespace: village-dev/namespace: village-prod/g; s/ENVIRONMENT: "dev"/ENVIRONMENT: "prod"/g' \
    "$K8S_DIR/frontend/configmap.yaml" | kubectl apply -f -
  
  # 4. Secrets PROD
  log_info "4/8 Secrets PROD..."
  if ! kubectl get secret backend-secret -n "$NAMESPACE" &>/dev/null; then
    read -rsp "  PROD DB_PASSWORD: " DB_PASSWORD
    echo ""
    read -rsp "  PROD JWT_SECRET: " JWT_SECRET
    echo ""
    
    kubectl create secret generic backend-secret \
      --from-literal=DB_PASSWORD="$DB_PASSWORD" \
      --from-literal=JWT_SECRET="$JWT_SECRET" \
      --namespace="$NAMESPACE"
  else
    log_warning "  Secret 'backend-secret' existe déjà en PROD, ignoré."
  fi
  
  # 5. Storage PROD
  log_info "5/8 Storage PROD..."
  sed 's/namespace: village-dev/namespace: village-prod/g' "$K8S_DIR/storage/pvc.yaml" | kubectl apply -f -
  
  # 6. Backend PROD (2 replicas)
  log_info "6/8 Backend PROD (2 replicas)..."
  sed 's/namespace: village-dev/namespace: village-prod/g; s/replicas: 1/replicas: 2/g' \
    "$K8S_DIR/backend/deployment.yaml" | kubectl apply -f -
  sed 's/namespace: village-dev/namespace: village-prod/g' "$K8S_DIR/backend/service.yaml" | kubectl apply -f -
  
  kubectl set image deployment/village-backend \
    backend="${REGISTRY}/${IMAGE_NAMESPACE}/village-backend:${VERSION}" \
    -n "$NAMESPACE"
  
  log_info "  Attente du rollout backend PROD..."
  kubectl rollout status deployment/village-backend -n "$NAMESPACE" --timeout=600s
  
  # 7. Frontend PROD (2 replicas)
  log_info "7/8 Frontend PROD (2 replicas)..."
  sed 's/namespace: village-dev/namespace: village-prod/g; s/replicas: 1/replicas: 2/g' \
    "$K8S_DIR/frontend/deployment.yaml" | kubectl apply -f -
  sed 's/namespace: village-dev/namespace: village-prod/g' "$K8S_DIR/frontend/service.yaml" | kubectl apply -f -
  
  kubectl set image deployment/village-frontend \
    frontend="${REGISTRY}/${IMAGE_NAMESPACE}/village-frontend:${VERSION}" \
    -n "$NAMESPACE"
  
  log_info "  Attente du rollout frontend PROD..."
  kubectl rollout status deployment/village-frontend -n "$NAMESPACE" --timeout=600s
  
  # 8. Ingress & NetworkPolicies PROD
  log_info "8/8 Ingress & NetworkPolicies PROD..."
  sed 's/namespace: village-dev/namespace: village-prod/g; s/village.local/village.example.com/g' \
    "$K8S_DIR/ingress/ingress.yaml" | kubectl apply -f -
  sed 's/namespace: village-dev/namespace: village-prod/g' "$K8S_DIR/security/networkpolicy.yaml" | kubectl apply -f -
}

# ──────────────────────────────────────────────────────────
# Annotation du déploiement (pour l'historique)
# ──────────────────────────────────────────────────────────
annotate_deployment() {
  log_info "Annotation du déploiement avec la version..."
  kubectl annotate deployment/village-frontend \
    kubernetes.io/change-cause="Version ${VERSION} deployed on $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -n "$NAMESPACE" --overwrite
  kubectl annotate deployment/village-backend \
    kubernetes.io/change-cause="Version ${VERSION} deployed on $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -n "$NAMESPACE" --overwrite
}

# ──────────────────────────────────────────────────────────
# Résumé
# ──────────────────────────────────────────────────────────
show_summary() {
  echo ""
  log_info "=== ✅ Déploiement PROD terminé ==="
  echo ""
  kubectl get all -n "$NAMESPACE"
  echo ""
  log_info "Version déployée: $VERSION"
  log_info "Historique: kubectl rollout history deployment/village-backend -n $NAMESPACE"
}

# ──────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────
main() {
  echo "============================================"
  echo "  🚀 Village App — Deploy PROD"
  echo "============================================"
  echo ""
  
  validate_args "$@"
  confirm_deployment
  check_cluster
  deploy_prod
  annotate_deployment
  show_summary
}

main "$@"

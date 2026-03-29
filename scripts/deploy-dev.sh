#!/usr/bin/env bash
# ============================================================
# Script de déploiement DEV
# Déploie l'application Village dans le namespace village-dev
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

NAMESPACE="village-dev"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(dirname "$SCRIPT_DIR")/k8s"

# Image tags (modifiables via variables d'environnement)
REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_NAMESPACE="${IMAGE_NAMESPACE:-abdenourdjouder}"
FRONTEND_TAG="${FRONTEND_TAG:-dev-latest}"
BACKEND_TAG="${BACKEND_TAG:-dev-latest}"

# ──────────────────────────────────────────────────────────
# Vérifications
# ──────────────────────────────────────────────────────────
check_cluster() {
  log_info "Vérification de la connexion au cluster..."
  kubectl cluster-info &>/dev/null || { log_error "Impossible de se connecter au cluster K8s"; exit 1; }
  log_info "✅ Cluster accessible."
}

# ──────────────────────────────────────────────────────────
# Déploiement
# ──────────────────────────────────────────────────────────
deploy() {
  log_info "=== Déploiement DEV (${NAMESPACE}) ==="
  
  # 1. Namespace
  log_info "1/8 Namespace..."
  kubectl apply -f "$K8S_DIR/namespace/dev-namespace.yaml"
  
  # 2. ServiceAccounts & RBAC
  log_info "2/8 ServiceAccounts & RBAC..."
  kubectl apply -f "$K8S_DIR/security/serviceaccount.yaml"
  kubectl apply -f "$K8S_DIR/security/rbac.yaml"
  
  # 3. ConfigMaps
  log_info "3/8 ConfigMaps..."
  kubectl apply -f "$K8S_DIR/backend/configmap.yaml"
  kubectl apply -f "$K8S_DIR/frontend/configmap.yaml"
  
  # 4. Secrets (demander si pas définis)
  log_info "4/8 Secrets..."
  if ! kubectl get secret backend-secret -n "$NAMESPACE" &>/dev/null; then
    DB_PASSWORD="${DB_PASSWORD:-}"
    JWT_SECRET="${JWT_SECRET:-}"
    
    if [ -z "$DB_PASSWORD" ]; then
      read -rsp "  DB_PASSWORD (dev): " DB_PASSWORD
      echo ""
    fi
    if [ -z "$JWT_SECRET" ]; then
      read -rsp "  JWT_SECRET (dev): " JWT_SECRET
      echo ""
    fi
    
    kubectl create secret generic backend-secret \
      --from-literal=DB_PASSWORD="$DB_PASSWORD" \
      --from-literal=JWT_SECRET="$JWT_SECRET" \
      --namespace="$NAMESPACE"
  else
    log_warning "  Secret 'backend-secret' existe déjà, ignoré."
  fi
  
  # 5. Storage (PV/PVC/PostgreSQL)
  log_info "5/8 Storage & PostgreSQL..."
  kubectl apply -f "$K8S_DIR/storage/pv.yaml"
  kubectl apply -f "$K8S_DIR/storage/pvc.yaml"
  
  # 6. Backend
  log_info "6/8 Backend (Spring Boot)..."
  kubectl apply -f "$K8S_DIR/backend/deployment.yaml"
  kubectl apply -f "$K8S_DIR/backend/service.yaml"
  kubectl set image deployment/village-backend \
    backend="${REGISTRY}/${IMAGE_NAMESPACE}/village-backend:${BACKEND_TAG}" \
    -n "$NAMESPACE" 2>/dev/null || true
  
  log_info "  Attente du rollout backend..."
  kubectl rollout status deployment/village-backend -n "$NAMESPACE" --timeout=300s
  
  # 7. Frontend
  log_info "7/8 Frontend (Angular)..."
  kubectl apply -f "$K8S_DIR/frontend/deployment.yaml"
  kubectl apply -f "$K8S_DIR/frontend/service.yaml"
  kubectl set image deployment/village-frontend \
    frontend="${REGISTRY}/${IMAGE_NAMESPACE}/village-frontend:${FRONTEND_TAG}" \
    -n "$NAMESPACE" 2>/dev/null || true
  
  log_info "  Attente du rollout frontend..."
  kubectl rollout status deployment/village-frontend -n "$NAMESPACE" --timeout=300s
  
  # 8. Ingress & NetworkPolicies
  log_info "8/8 Ingress & NetworkPolicies..."
  kubectl apply -f "$K8S_DIR/ingress/ingress.yaml"
  kubectl apply -f "$K8S_DIR/security/networkpolicy.yaml"
}

# ──────────────────────────────────────────────────────────
# Résumé
# ──────────────────────────────────────────────────────────
show_summary() {
  echo ""
  log_info "=== ✅ Déploiement DEV terminé ==="
  echo ""
  kubectl get all -n "$NAMESPACE"
  echo ""
  
  MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "N/A")
  log_info "URLs d'accès:"
  log_info "  Frontend : http://${MINIKUBE_IP}:30080"
  log_info "  Backend  : http://${MINIKUBE_IP}:30081"
  log_info "  Ingress  : http://village.local (ajouter dans /etc/hosts)"
  echo ""
  log_info "Commandes utiles:"
  log_info "  kubectl get all -n ${NAMESPACE}"
  log_info "  kubectl logs -f deployment/village-backend -n ${NAMESPACE}"
  log_info "  kubectl logs -f deployment/village-frontend -n ${NAMESPACE}"
}

# ──────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────
main() {
  echo "============================================"
  echo "  🚀 Village App — Deploy DEV"
  echo "============================================"
  echo ""
  
  check_cluster
  deploy
  show_summary
}

main "$@"

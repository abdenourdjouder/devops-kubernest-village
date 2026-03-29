#!/usr/bin/env bash
# ============================================================
# Script d'initialisation du cluster Kubernetes local
# Utilise Minikube pour le développement local
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ──────────────────────────────────────────────────────────
# Vérifier les prérequis
# ──────────────────────────────────────────────────────────
check_prerequisites() {
  log_info "Vérification des prérequis..."
  
  local missing=()
  
  command -v kubectl  &>/dev/null || missing+=("kubectl")
  command -v docker   &>/dev/null || missing+=("docker")
  command -v minikube &>/dev/null || missing+=("minikube")
  
  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Outils manquants: ${missing[*]}"
    log_error "Installez-les avant de continuer."
    echo ""
    echo "  kubectl  : https://kubernetes.io/docs/tasks/tools/"
    echo "  docker   : https://docs.docker.com/get-docker/"
    echo "  minikube : https://minikube.sigs.k8s.io/docs/start/"
    exit 1
  fi
  
  log_info "✅ Tous les prérequis sont présents."
}

# ──────────────────────────────────────────────────────────
# Démarrer Minikube
# ──────────────────────────────────────────────────────────
start_minikube() {
  log_info "Démarrage de Minikube..."
  
  if minikube status &>/dev/null; then
    log_warning "Minikube est déjà en cours d'exécution."
  else
    minikube start \
      --driver=docker \
      --cpus=2 \
      --memory=4096 \
      --disk-size=20g \
      --kubernetes-version=v1.28.0
    
    log_info "✅ Minikube démarré."
  fi
}

# ──────────────────────────────────────────────────────────
# Activer les addons Minikube
# ──────────────────────────────────────────────────────────
enable_addons() {
  log_info "Activation des addons Minikube..."
  
  minikube addons enable ingress
  log_info "  ✅ ingress"
  
  minikube addons enable metrics-server
  log_info "  ✅ metrics-server"
  
  minikube addons enable dashboard
  log_info "  ✅ dashboard"
}

# ──────────────────────────────────────────────────────────
# Créer les namespaces
# ──────────────────────────────────────────────────────────
create_namespaces() {
  log_info "Création des namespaces..."
  
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  K8S_DIR="$(dirname "$SCRIPT_DIR")/k8s"
  
  kubectl apply -f "$K8S_DIR/namespace/dev-namespace.yaml"
  kubectl apply -f "$K8S_DIR/namespace/prod-namespace.yaml"
  
  log_info "✅ Namespaces créés: village-dev, village-prod"
}

# ──────────────────────────────────────────────────────────
# Afficher les informations du cluster
# ──────────────────────────────────────────────────────────
show_cluster_info() {
  log_info "=== Informations du cluster ==="
  echo ""
  kubectl cluster-info
  echo ""
  kubectl get nodes -o wide
  echo ""
  kubectl get namespaces
  echo ""
  log_info "IP Minikube: $(minikube ip)"
  log_info ""
  log_info "Pour accéder au dashboard: minikube dashboard"
  log_info "Pour accéder aux services:"
  log_info "  Frontend: http://$(minikube ip):30080"
  log_info "  Backend:  http://$(minikube ip):30081"
}

# ──────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────
main() {
  echo "============================================"
  echo "  🚀 Village App — Cluster Setup"
  echo "============================================"
  echo ""
  
  check_prerequisites
  start_minikube
  enable_addons
  create_namespaces
  show_cluster_info
  
  echo ""
  echo "============================================"
  echo "  ✅ Cluster prêt !"
  echo "  Prochain: ./scripts/deploy-dev.sh"
  echo "============================================"
}

main "$@"

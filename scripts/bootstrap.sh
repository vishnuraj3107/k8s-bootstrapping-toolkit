#!/bin/bash

# =============================================================================
# Kubernetes Bootstrapping Toolkit - Main Bootstrap Script
# Author: Vishnu Raj
# Description: Provisions a production-ready Kubernetes cluster with
#              Prometheus, Grafana, and NGINX Ingress using Helm
# =============================================================================

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ─── Configuration ────────────────────────────────────────────────────────────
MONITORING_NAMESPACE="monitoring"
APP_NAMESPACE="app"
INGRESS_NAMESPACE="ingress-nginx"
GRAFANA_PASSWORD="admin123"

# ─── Logging Helpers ──────────────────────────────────────────────────────────
log_info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════${NC}\n"; }

# ─── Prerequisite Check ───────────────────────────────────────────────────────
check_prerequisites() {
  log_section "Checking Prerequisites"

  local tools=("kubectl" "helm" "minikube" "docker")
  for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      log_info "$tool ✓ ($(command -v $tool))"
    else
      log_error "$tool is not installed. Please install it and re-run."
      exit 1
    fi
  done
}

# ─── Helm Repo Setup ──────────────────────────────────────────────────────────
setup_helm_repos() {
  log_section "Setting Up Helm Repositories"

  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo add grafana https://grafana.github.io/helm-charts
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo update

  log_info "All Helm repositories added and updated."
}

# ─── Namespace Creation ───────────────────────────────────────────────────────
create_namespaces() {
  log_section "Creating Kubernetes Namespaces"

  for ns in "$MONITORING_NAMESPACE" "$APP_NAMESPACE" "$INGRESS_NAMESPACE"; do
    if kubectl get namespace "$ns" &>/dev/null; then
      log_warn "Namespace '$ns' already exists. Skipping."
    else
      kubectl create namespace "$ns"
      log_info "Created namespace: $ns"
    fi
  done
}

# ─── Deploy NGINX Ingress ─────────────────────────────────────────────────────
deploy_ingress() {
  log_section "Deploying NGINX Ingress Controller"

  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace "$INGRESS_NAMESPACE" \
    --create-namespace \
    -f helm/ingress-nginx/values.yaml \
    --wait --timeout 5m

  log_info "NGINX Ingress Controller deployed successfully."
}

# ─── Deploy Prometheus Stack ──────────────────────────────────────────────────
deploy_prometheus() {
  log_section "Deploying Prometheus Monitoring Stack"

  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace "$MONITORING_NAMESPACE" \
    --create-namespace \
    -f helm/prometheus/values.yaml \
    --wait --timeout 10m

  log_info "Prometheus stack deployed successfully."
}

# ─── Deploy Grafana ───────────────────────────────────────────────────────────
deploy_grafana() {
  log_section "Deploying Grafana"

  helm upgrade --install grafana grafana/grafana \
    --namespace "$MONITORING_NAMESPACE" \
    -f helm/grafana/values.yaml \
    --set adminPassword="$GRAFANA_PASSWORD" \
    --wait --timeout 5m

  log_info "Grafana deployed successfully."
}

# ─── Deploy Sample Application ────────────────────────────────────────────────
deploy_app() {
  log_section "Deploying Sample Application"

  kubectl apply -f app/k8s/deployment.yaml -n "$APP_NAMESPACE"
  kubectl apply -f app/k8s/service.yaml    -n "$APP_NAMESPACE"
  kubectl apply -f app/k8s/ingress.yaml    -n "$APP_NAMESPACE"

  kubectl rollout status deployment/sample-app -n "$APP_NAMESPACE" --timeout=3m
  log_info "Sample application deployed and healthy."
}

# ─── Apply Alert Rules ────────────────────────────────────────────────────────
apply_alert_rules() {
  log_section "Applying Prometheus Alert Rules"

  kubectl apply -f monitoring/alerts/alert-rules.yaml -n "$MONITORING_NAMESPACE"
  log_info "Alert rules applied."
}

# ─── Print Access Info ────────────────────────────────────────────────────────
print_access_info() {
  log_section "🎉 Bootstrap Complete — Access Information"

  MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")

  echo -e "${GREEN}Grafana Dashboard:${NC}"
  echo -e "  URL:      http://$MINIKUBE_IP or use: kubectl port-forward svc/grafana -n monitoring 3000:80"
  echo -e "  Username: admin"
  echo -e "  Password: $GRAFANA_PASSWORD"
  echo ""
  echo -e "${GREEN}Prometheus:${NC}"
  echo -e "  kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090"
  echo ""
  echo -e "${GREEN}Sample App:${NC}"
  echo -e "  kubectl port-forward svc/sample-app -n app 8080:80"
  echo ""
  echo -e "${YELLOW}Tip:${NC} Run ./scripts/health-check.sh to verify all pods are Running."
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  log_section "Kubernetes Bootstrapping Toolkit"
  echo -e "  Author: Vishnu Raj | github.com/vishnu-raj\n"

  check_prerequisites
  setup_helm_repos
  create_namespaces
  deploy_ingress
  deploy_prometheus
  deploy_grafana
  deploy_app
  apply_alert_rules
  print_access_info
}

main "$@"

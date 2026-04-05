#!/bin/bash

# =============================================================================
# Kubernetes Bootstrapping Toolkit - Teardown Script
# Author: Vishnu Raj
# Description: Cleanly removes all deployed resources from the cluster
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_section() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════${NC}\n"; }

log_section "Tearing Down All Resources"

log_info "Removing sample application..."
kubectl delete -f app/k8s/ -n app --ignore-not-found

log_info "Uninstalling Grafana..."
helm uninstall grafana -n monitoring --ignore-not-found 2>/dev/null || true

log_info "Uninstalling Prometheus stack..."
helm uninstall prometheus -n monitoring --ignore-not-found 2>/dev/null || true

log_info "Uninstalling NGINX Ingress..."
helm uninstall ingress-nginx -n ingress-nginx --ignore-not-found 2>/dev/null || true

log_info "Deleting namespaces..."
for ns in monitoring app ingress-nginx; do
  kubectl delete namespace "$ns" --ignore-not-found
done

log_info "✅ Teardown complete. Cluster is clean."

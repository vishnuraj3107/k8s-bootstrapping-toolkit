#!/bin/bash

# =============================================================================
# Kubernetes Bootstrapping Toolkit - Health Check Script
# Author: Vishnu Raj
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[FAIL]${NC}  $1"; }
log_section() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════${NC}\n"; }

ERRORS=0

check_namespace_pods() {
  local namespace=$1
  local label=$2

  log_section "Checking pods in namespace: $namespace"

  local pods
  pods=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null)

  if [[ -z "$pods" ]]; then
    log_warn "No pods found in namespace '$namespace'."
    return
  fi

  while IFS= read -r line; do
    local pod_name status ready
    pod_name=$(echo "$line" | awk '{print $1}')
    ready=$(echo "$line" | awk '{print $2}')
    status=$(echo "$line" | awk '{print $3}')

    if [[ "$status" == "Running" ]]; then
      log_info "$pod_name → $status ($ready)"
    elif [[ "$status" == "Completed" ]]; then
      log_info "$pod_name → $status (job done)"
    else
      log_error "$pod_name → $status ($ready)"
      ((ERRORS++))
    fi
  done <<< "$pods"
}

check_helm_releases() {
  log_section "Helm Release Status"

  helm list -A --output table | tail -n +2 | while IFS= read -r line; do
    local name status
    name=$(echo "$line" | awk '{print $1}')
    status=$(echo "$line" | awk '{print $8}')

    if [[ "$status" == "deployed" ]]; then
      log_info "Helm release '$name' → $status"
    else
      log_error "Helm release '$name' → $status"
      ((ERRORS++))
    fi
  done
}

check_namespace_pods "monitoring"
check_namespace_pods "app"
check_namespace_pods "ingress-nginx"
check_helm_releases

echo ""
if [[ "$ERRORS" -eq 0 ]]; then
  echo -e "${GREEN}✅ All systems healthy. No issues found.${NC}"
else
  echo -e "${RED}❌ Found $ERRORS unhealthy resource(s). Check above for details.${NC}"
  exit 1
fi

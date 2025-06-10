#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="egov-db"
YAMLS=("opensearch.yaml" "opensearch-pv-nfs.yaml")

apply() {
  for y in "${YAMLS[@]}"; do
    kubectl apply -f "$y"
  done
}

status() {
  kubectl get all -n "$NAMESPACE"
}

main() {
  apply
  status
  echo "🔎  kubectl get all -n $NAMESPACE 로 상태를 다시 확인하세요."
}

main "$@"

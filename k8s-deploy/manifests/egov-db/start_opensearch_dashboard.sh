#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="egov-db"
FILE="opensearch-dashboard.yaml"

kubectl apply -f "$FILE"          # 배포
kubectl get all -n "$NAMESPACE"   # 상태 확인

echo "🔎  kubectl get all -n $NAMESPACE 로 다시 확인하세요."

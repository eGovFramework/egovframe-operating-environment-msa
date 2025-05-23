#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Istio 매니페스트 정리
echo -e "${YELLOW}Removing Istio manifests...${NC}"
kubectl delete -f ../../manifests/egov-istio/telemetry.yaml --ignore-not-found=true
kubectl delete -f ../../manifests/egov-istio/config.yaml --ignore-not-found=true

# Istio injection 레이블 제거 (네임스페이스가 존재하는 경우에만)
echo -e "${YELLOW}Removing Istio injection labels from namespaces...${NC}"
if kubectl get namespace egov-app >/dev/null 2>&1; then
    kubectl label namespace egov-app istio-injection- 2>/dev/null || true
fi

# Istio 제거
echo -e "${YELLOW}Uninstalling Istio...${NC}"

# istioctl이 설치되어 있는지 확인
if command -v istioctl >/dev/null 2>&1; then
    # Istio 제거 시도
    if ! istioctl uninstall --purge -y; then
        echo -e "${YELLOW}Trying alternative uninstall method...${NC}"
        # Istio 관련 리소스 직접 제거
        kubectl delete mutatingwebhookconfiguration istio-sidecar-injector --ignore-not-found=true
        kubectl delete validatingwebhookconfiguration istiod-istio-system --ignore-not-found=true
        kubectl delete -n istio-system --all 2>/dev/null || true
    fi
else
    echo -e "${YELLOW}istioctl not found, using direct cleanup method...${NC}"
    kubectl delete mutatingwebhookconfiguration istio-sidecar-injector --ignore-not-found=true
    kubectl delete validatingwebhookconfiguration istiod-istio-system --ignore-not-found=true
    kubectl delete -n istio-system --all 2>/dev/null || true
fi

# 네임스페이스 삭제
echo -e "${YELLOW}Removing namespaces...${NC}"
kubectl delete namespace istio-system --ignore-not-found=true

echo -e "${GREEN}Istio cleanup completed!${NC}"

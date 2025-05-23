#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Application 서비스 제거 (egov-app 네임스페이스)
echo -e "${YELLOW}Removing application services...${NC}"

# 각 서비스 제거
SERVICES=(
    "egov-hello"
    "egov-main"
    "egov-board"
    "egov-login"
    "egov-author"
    "egov-mobileid"
    "egov-questionnaire"
    "egov-cmmncode"
    "egov-search"
)

for service in "${SERVICES[@]}"; do
    echo -e "${GREEN}Removing ${service}...${NC}"
    kubectl delete -f "../../manifests/egov-app/${service}-deployment.yaml" 2>/dev/null || true
done

# ConfigMap 제거
echo -e "${GREEN}Removing ConfigMaps in egov-app namespace...${NC}"
kubectl delete configmap -n egov-app --all

# MySQL Secret 제거
echo -e "${GREEN}Removing MySQL Secret in egov-app namespace...${NC}"
kubectl delete secret mysql-secret -n egov-app 2>/dev/null || true

# EgovMobileId PV/PVC 제거
echo -e "${GREEN}Removing EgovMobileId PV and PVC...${NC}"
kubectl delete -f "../../manifests/egov-app/egov-mobileid-pv.yaml" 2>/dev/null || true

# PVC가 Terminating 상태인 경우 강제 삭제
if kubectl get pvc egov-mobileid-pvc -n egov-app 2>/dev/null | grep Terminating; then
    echo -e "${YELLOW}PVC stuck in Terminating state, forcing deletion...${NC}"
    kubectl delete pvc egov-mobileid-pvc -n egov-app --force --grace-period=0
fi

# PV가 Terminating 상태인 경우 강제 삭제
if kubectl get pv egov-mobileid-pv 2>/dev/null | grep Terminating; then
    echo -e "${YELLOW}PV stuck in Terminating state, forcing deletion...${NC}"
    kubectl patch pv egov-mobileid-pv -p '{"metadata":{"finalizers":null}}'
    kubectl delete pv egov-mobileid-pv --force --grace-period=0
fi

# EgovSearch PV/PVC 제거
echo -e "${GREEN}Removing EgovSearch PV and PVC...${NC}"
kubectl delete -f "../../manifests/egov-app/egov-search-pv.yaml" 2>/dev/null || true

# 리소스 제거 완료 대기
echo -e "\n${YELLOW}Waiting for resources to be terminated...${NC}"
echo -e "${YELLOW}Waiting for egov-app resources...${NC}"
kubectl wait --for=delete pods --all -n egov-app --timeout=60s 2>/dev/null || true

# 최종 상태 확인
echo -e "\n${YELLOW}Checking remaining resources in egov-app:${NC}"
kubectl get all -n egov-app

# ConfigMap 상태 확인
echo -e "\n${YELLOW}Checking remaining ConfigMaps in egov-app:${NC}"
kubectl get configmap -n egov-app

# PV/PVC 상태 확인
echo -e "\n${YELLOW}Checking remaining PV/PVC:${NC}"
echo -e "${GREEN}PVCs in egov-app namespace:${NC}"
kubectl get pvc -n egov-app
echo -e "\n${GREEN}PVs:${NC}"
kubectl get pv | grep egov-mobileid
kubectl get pv | grep egov-search

echo -e "\n${GREEN}Application cleanup completed!${NC}"

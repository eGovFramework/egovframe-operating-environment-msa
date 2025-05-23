#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 함수: 배포 상태 확인
check_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=600  # 10분으로 증가
    local interval=30
    local elapsed=0

    echo -e "${YELLOW}Waiting for deployment ${deployment} in namespace ${namespace}...${NC}"
    
    while [ $elapsed -lt $timeout ]; do
        if kubectl get deployment -n $namespace $deployment -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' | grep -q "True"; then
            echo -e "${GREEN}Deployment ${deployment} is ready${NC}"
            return 0
        fi
        echo -e "${YELLOW}Still waiting for ${deployment} (${elapsed}s/${timeout}s)...${NC}"
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    echo -e "${RED}Timeout waiting for deployment ${deployment}${NC}"
    echo -e "${YELLOW}Checking pod status:${NC}"
    kubectl get pods -n $namespace -l app=$deployment
    kubectl describe deployment -n $namespace $deployment
    return 1
}

# Application 서비스 설치 (egov-app 네임스페이스)
echo -e "${YELLOW}Installing application services...${NC}"

# MySQL Secret 복사 (egov-db -> egov-app)
echo -e "${GREEN}Copying MySQL Secret from egov-db to egov-app namespace...${NC}"
kubectl get secret mysql-secret -n egov-db -o yaml | sed 's/namespace: egov-db/namespace: egov-app/' | kubectl apply -f -

# MobileId PV/PVC 생성
echo -e "${GREEN}Creating MobileId PV and PVC...${NC}"
kubectl apply -f "../../manifests/egov-app/egov-mobileid-pv.yaml"

# EgovSearch PV/PVC 생성
echo -e "${GREEN}Creating EgovSearch PV and PVC...${NC}"
kubectl apply -f "../../manifests/egov-app/egov-search-pv.yaml"

# 각 서비스 배포
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
    "egov-common-all"
)

# 먼저 모든 서비스 배포
for service in "${SERVICES[@]}"; do
    echo -e "${GREEN}Installing ${service}...${NC}"
    kubectl apply -f "../../manifests/egov-app/${service}-deployment.yaml"
done

# 모든 서비스의 배포 상태를 한번에 확인
echo -e "\n${YELLOW}Checking all service deployments...${NC}"
for service in "${SERVICES[@]}"; do
    check_deployment "egov-app" "${service}"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to deploy ${service}${NC}"
        exit 1
    fi
done

# 상태 확인
echo -e "\n${YELLOW}Checking application services status:${NC}"
kubectl get pods,svc -n egov-app

# PV/PVC 상태 확인
echo -e "\n${YELLOW}Checking EgovMobileId PV/PVC status:${NC}"
echo -e "${GREEN}PVCs in egov-app namespace:${NC}"
kubectl get pvc -n egov-app | grep mobileid
echo -e "\n${GREEN}PVs:${NC}"
kubectl get pv | grep mobileid

echo -e "\n${YELLOW}Checking EgovSearch PV/PVC status:${NC}"
echo -e "${GREEN}PVCs in egov-app namespace:${NC}"
kubectl get pvc -n egov-app | grep search
echo -e "\n${GREEN}PVs:${NC}"
kubectl get pv | grep search

echo -e "\n${GREEN}Application services installation completed successfully!${NC}"

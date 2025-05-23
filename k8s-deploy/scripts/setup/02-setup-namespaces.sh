#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 네임스페이스 생성 함수
create_namespace() {
    local ns=$1
    if kubectl get namespace $ns >/dev/null 2>&1; then
        echo -e "${YELLOW}Namespace '$ns' already exists${NC}"
    else
        kubectl create namespace $ns
        echo -e "${GREEN}Created namespace '$ns'${NC}"
    fi
}

# 필요한 네임스페이스 생성
echo -e "${YELLOW}Creating namespaces...${NC}"

# 인프라 네임스페이스
create_namespace "egov-infra"        # 인프라 서비스용 (Config, Eureka, Gateway)

# 애플리케이션 네임스페이스
create_namespace "egov-app"          # 애플리케이션 서비스용

# 데이터베이스 네임스페이스
create_namespace "egov-db"           # 데이터베이스용

# CICD 네임스페이스
create_namespace "egov-cicd"         # CICD 도구용

# 모니터링 네임스페이스
create_namespace "egov-monitoring"   # 모니터링 도구용

# 네임스페이스 목록 확인
echo -e "\n${YELLOW}Current namespaces:${NC}"
kubectl get namespaces

# 컨텍스트 설정
echo -e "\n${YELLOW}Setting up kubectl contexts...${NC}"
kubectl config set-context egov-infra --namespace=egov-infra --cluster=$(kubectl config current-context | cut -d/ -f1) --user=$(kubectl config current-context | cut -d/ -f2)
kubectl config set-context egov-app --namespace=egov-app --cluster=$(kubectl config current-context | cut -d/ -f1) --user=$(kubectl config current-context | cut -d/ -f2)
kubectl config set-context egov-db --namespace=egov-db --cluster=$(kubectl config current-context | cut -d/ -f1) --user=$(kubectl config current-context | cut -d/ -f2)
kubectl config set-context egov-monitoring --namespace=egov-monitoring --cluster=$(kubectl config current-context | cut -d/ -f1) --user=$(kubectl config current-context | cut -d/ -f2)

echo -e "\n${GREEN}Namespace setup completed!${NC}"
echo -e "${YELLOW}You can switch contexts using:${NC}"

# 필요한 네임스페이스에 사이드카 주입 활성화
echo "Enabling sidecar injection for required namespaces..."
kubectl label namespace egov-infra istio-injection=enabled --overwrite

# 공통적으로 사용할 ConfigMap 생성
kubectl apply -f ../../manifests/common/egov-common-configmap.yaml -n egov-app
kubectl apply -f ../../manifests/common/egov-common-configmap.yaml -n egov-infra

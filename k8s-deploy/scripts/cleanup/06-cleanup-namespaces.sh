#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 제거할 네임스페이스 배열
NAMESPACES=(
    "egov-infra"
    "egov-app"
    "egov-db"
    "egov-cicd"
    "egov-monitoring"
)

# 네임스페이스 제거 함수
delete_namespace() {
    local ns=$1
    echo -e "${YELLOW}Checking namespace '$ns'...${NC}"
    
    if kubectl get namespace $ns >/dev/null 2>&1; then
        echo -e "${YELLOW}Removing all resources in namespace '$ns'...${NC}"
        
        # istio-injection 레이블 제거 (있는 경우)
        kubectl label namespace $ns istio-injection- 2>/dev/null || true
        
        # 네임스페이스 내의 모든 리소스 제거
        kubectl delete all --all -n $ns
        
        # 네임스페이스 제거
        echo -e "${YELLOW}Deleting namespace '$ns'...${NC}"
        kubectl delete namespace $ns
        
        # 네임스페이스가 완전히 제거될 때까지 대기
        while kubectl get namespace $ns >/dev/null 2>&1; do
            echo -e "${YELLOW}Waiting for namespace '$ns' to be removed...${NC}"
            sleep 2
        done
        
        echo -e "${GREEN}Namespace '$ns' has been removed${NC}"
    else
        echo -e "${YELLOW}Namespace '$ns' does not exist${NC}"
    fi
}

# 메인 실행
echo -e "${YELLOW}Starting namespace cleanup...${NC}"

# 각 네임스페이스 제거
for ns in "${NAMESPACES[@]}"; do
    delete_namespace $ns
done

# kubectl 컨텍스트 제거
echo -e "${YELLOW}Removing kubectl contexts...${NC}"
for ns in "${NAMESPACES[@]}"; do
    kubectl config delete-context $ns 2>/dev/null || true
done

echo -e "${GREEN}Namespace cleanup completed!${NC}"

# 남아있는 네임스페이스 목록 표시
echo -e "\n${YELLOW}Current namespaces:${NC}"
kubectl get namespaces

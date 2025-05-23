#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# MySQL 설치 함수
setup_mysql() {
    echo -e "${YELLOW}Installing MySQL...${NC}"

    # MySQL 리소스 생성
    echo -e "${GREEN}Creating MySQL resources...${NC}"
    kubectl apply -f ../../manifests/egov-db/mysql-pv.yaml

    # PVC 바인딩 상태 확인
    echo -e "${YELLOW}Waiting for MySQL PVC to be bound...${NC}"
    while [[ $(kubectl get pvc mysql-pvc-nfs -n egov-db -o jsonpath='{.status.phase}') != "Bound" ]]; do
        echo -e "${YELLOW}Waiting for PVC to be bound...${NC}"
        sleep 5
    done

    kubectl apply -f ../../manifests/egov-db/mysql.yaml

    # MySQL 배포 상태 확인
    echo -e "${YELLOW}Waiting for MySQL resources...${NC}"
    kubectl rollout status statefulset/mysql -n egov-db --timeout=600s

    # MySQL 상태 확인
    echo -e "\n${YELLOW}Checking MySQL pod status:${NC}"
    kubectl get pods -n egov-db -l app=mysql -o wide

    # MySQL 로그 확인
    echo -e "\n${YELLOW}Checking MySQL logs:${NC}"
    MYSQL_POD=$(kubectl get pods -n egov-db -l app=mysql -o jsonpath='{.items[0].metadata.name}')
    kubectl logs $MYSQL_POD -n egov-db -c mysql

    # 접근 URL 출력
    echo -e "\n${YELLOW}MySQL Access URLs:${NC}"
    MYSQL_PORT=$(kubectl get svc mysql -n egov-db -o jsonpath='{.spec.ports[0].nodePort}')
    echo -e "${GREEN}MySQL: localhost:${MYSQL_PORT}${NC}"

    echo -e "\n${GREEN}MySQL installation completed successfully!${NC}"
}

# OpenSearch 설치 함수
setup_opensearch() {
    echo -e "\n${YELLOW}Installing OpenSearch...${NC}"

    # OpenSearch 리소스 생성
    echo -e "${GREEN}Creating OpenSearch resources...${NC}"
    kubectl apply -f ../../manifests/egov-db/opensearch-pv.yaml

    # PVC 바인딩 상태 확인
    echo -e "${YELLOW}Waiting for OpenSearch PVC to be bound...${NC}"
    while [[ $(kubectl get pvc opensearch-pvc-nfs -n egov-db -o jsonpath='{.status.phase}') != "Bound" ]]; do
        echo -e "${YELLOW}Waiting for PVC to be bound...${NC}"
        sleep 5
    done

    kubectl apply -f ../../manifests/egov-db/opensearch.yaml

    # OpenSearch Dashboard 생성
    echo -e "${GREEN}Creating OpenSearch Dashboard...${NC}"
    kubectl apply -f ../../manifests/egov-db/opensearch-dashboard.yaml

    # OpenSearch 배포 상태 확인
    echo -e "${YELLOW}Waiting for OpenSearch StatefulSet...${NC}"
    kubectl rollout status statefulset/opensearch -n egov-db --timeout=390s

    # OpenSearch Dashboard 배포 상태 확인
    echo -e "${YELLOW}Waiting for OpenSearch Dashboard...${NC}"
    kubectl rollout status deployment/opensearch-dashboards -n egov-db --timeout=300s

    # OpenSearch 상태 확인
    echo -e "\n${YELLOW}Checking OpenSearch resources:${NC}"
    kubectl get pods -n egov-db -l app=opensearch -o wide
    kubectl get pods -n egov-db -l app=opensearch-dashboards -o wide

    # 접근 URL 출력
    echo -e "\n${YELLOW}OpenSearch Access URLs:${NC}"
    OS_PORT=$(kubectl get svc opensearch -n egov-db -o jsonpath='{.spec.ports[0].nodePort}')
    OS_DASHBOARD_PORT=$(kubectl get svc opensearch-dashboards -n egov-db -o jsonpath='{.spec.ports[0].nodePort}')
    echo -e "${GREEN}OpenSearch: localhost:${OS_PORT}${NC}"
    echo -e "${GREEN}OpenSearch Dashboards: localhost:${OS_DASHBOARD_PORT}${NC}"

    echo -e "\n${GREEN}OpenSearch installation completed successfully!${NC}"
}

# PostgreSQL 설치 함수
setup_postgresql() {
    echo -e "\n${YELLOW}Installing PostgreSQL...${NC}"

    # PostgreSQL 리소스 생성
    echo -e "${GREEN}Creating PostgreSQL resources...${NC}"

    # PV/PVC 생성
    kubectl apply -f ../../manifests/egov-db/postgresql-pv.yaml

    # PVC 바인딩 상태 확인
    echo -e "${YELLOW}Waiting for PostgreSQL PVC to be bound...${NC}"
    while [[ $(kubectl get pvc postgresql-pvc-nfs -n egov-db -o jsonpath='{.status.phase}') != "Bound" ]]; do
        echo -e "${YELLOW}Waiting for PVC to be bound...${NC}"
        sleep 5
    done

    # PostgreSQL 생성
    kubectl apply -f ../../manifests/egov-db/postgresql.yaml

    # PostgreSQL 배포 상태 확인
    echo -e "${YELLOW}Waiting for PostgreSQL StatefulSet...${NC}"
    kubectl rollout status statefulset/postgresql -n egov-db --timeout=300s

    echo -e "\n${GREEN}PostgreSQL installation completed successfully!${NC}"
}

# Redis 설치 함수
setup_redis() {
    echo -e "\n${YELLOW}Installing Redis...${NC}"

    # Redis 리소스 생성
    echo -e "${GREEN}Creating Redis resources...${NC}"

    # PV/PVC 생성
    kubectl apply -f ../../manifests/egov-db/redis-pv.yaml

    # PVC 바인딩 상태 확인
    echo -e "${YELLOW}Waiting for Redis PVC to be bound...${NC}"
    while [[ $(kubectl get pvc redis-pvc-nfs -n egov-db -o jsonpath='{.status.phase}') != "Bound" ]]; do
        echo -e "${YELLOW}Waiting for PVC to be bound...${NC}"
        sleep 5
    done

    # Redis 생성
    kubectl apply -f ../../manifests/egov-db/redis.yaml

    # Redis 배포 상태 확인
    echo -e "${YELLOW}Waiting for Redis StatefulSet...${NC}"
    kubectl rollout status statefulset/redis -n egov-db --timeout=300s

    echo -e "\n${GREEN}Redis installation completed successfully!${NC}"
}

# 메인 실행
echo -e "${YELLOW}Starting database installations...${NC}"

# MySQL 설치
setup_mysql

# OpenSearch 설치
setup_opensearch

# PostgreSQL 설치
setup_postgresql

# Redis 설치
setup_redis

# 최종 상태 확인
echo -e "\n${YELLOW}Final status check for database resources:${NC}"
echo -e "\n${GREEN}Pods in egov-db namespace:${NC}"
kubectl get pods -n egov-db
echo -e "\n${GREEN}Services in egov-db namespace:${NC}"
kubectl get svc -n egov-db
echo -e "\n${GREEN}PVCs in egov-db namespace:${NC}"
kubectl get pvc -n egov-db

echo -e "\n${GREEN}All database installations completed successfully!${NC}"

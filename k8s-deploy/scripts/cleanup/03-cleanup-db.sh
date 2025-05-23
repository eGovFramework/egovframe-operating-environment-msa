#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# MySQL 정리 함수
cleanup_mysql() {
    echo -e "${YELLOW}Removing MySQL resources...${NC}"
    kubectl delete -f ../../manifests/egov-db/mysql.yaml 2>/dev/null || true

    echo -e "${GREEN}Removing MySQL PV and PVC...${NC}"
    kubectl delete pvc mysql-pvc-nfs -n egov-db --force --grace-period=0 2>/dev/null || true
    kubectl delete pv mysql-pv-nfs --force --grace-period=0 2>/dev/null || true

    # 리소스 제거 완료 대기
    echo -e "\n${YELLOW}Waiting for MySQL resources to be terminated...${NC}"
    kubectl wait --for=delete pods -l app=mysql -n egov-db --timeout=60s 2>/dev/null || true

    # 최종 상태 확인
    echo -e "\n${YELLOW}Checking remaining MySQL resources in egov-db:${NC}"
    kubectl get pods -l app=mysql -n egov-db
    echo -e "\n${YELLOW}Checking remaining MySQL PV/PVC:${NC}"
    echo -e "${GREEN}PVCs in egov-db namespace:${NC}"
    kubectl get pvc -n egov-db | grep mysql
    echo -e "\n${GREEN}PVs:${NC}"
    kubectl get pv | grep mysql

    echo -e "\n${GREEN}MySQL cleanup completed!${NC}"
}

# OpenSearch 정리 함수
cleanup_opensearch() {
    echo -e "${YELLOW}Removing OpenSearch resources...${NC}"
    kubectl delete -f ../../manifests/egov-db/opensearch-dashboard.yaml 2>/dev/null || true

    echo -e "${GREEN}Removing OpenSearch StatefulSet and Services...${NC}"
    kubectl delete -f ../../manifests/egov-db/opensearch.yaml 2>/dev/null || true

    kubectl delete -f ../../manifests/egov-db/opensearch-pv.yaml 2>/dev/null || true

    # PVC가 Terminating 상태인 경우 강제 삭제
    if kubectl get pvc opensearch-pvc-nfs -n egov-db 2>/dev/null | grep Terminating; then
        echo -e "${YELLOW}PVC stuck in Terminating state, forcing deletion...${NC}"
        kubectl delete pvc opensearch-pvc-nfs -n egov-db --force --grace-period=0
    fi

    # PV가 Terminating 상태인 경우 강제 삭제
    if kubectl get pv opensearch-pv-nfs 2>/dev/null | grep Terminating; then
        echo -e "${YELLOW}PV stuck in Terminating state, forcing deletion...${NC}"
        kubectl patch pv opensearch-pv-nfs -p '{"metadata":{"finalizers":null}}'
        kubectl delete pv opensearch-pv-nfs --force --grace-period=0
    fi

    # 리소스 제거 완료 대기
    echo -e "\n${YELLOW}Waiting for OpenSearch resources to be terminated...${NC}"
    kubectl wait --for=delete pods -l app=opensearch -n egov-db --timeout=60s 2>/dev/null || true

    # 최종 상태 확인
    echo -e "\n${YELLOW}Checking remaining OpenSearch resources in egov-db:${NC}"
    kubectl get pods -l app=opensearch -n egov-db
    echo -e "\n${YELLOW}Checking remaining OpenSearch PV/PVC:${NC}"
    echo -e "${GREEN}PVCs in egov-db namespace:${NC}"
    kubectl get pvc -n egov-db | grep opensearch
    echo -e "\n${GREEN}PVs:${NC}"
    kubectl get pv | grep opensearch

    echo -e "\n${GREEN}OpenSearch cleanup completed!${NC}"
}

# PostgreSQL 정리 함수
cleanup_postgresql() {
    echo -e "${YELLOW}Removing PostgreSQL resources...${NC}"
    kubectl delete -f ../../manifests/egov-db/postgresql.yaml 2>/dev/null || true

    echo -e "${GREEN}Removing PostgreSQL PV and PVC...${NC}"
    kubectl delete -f ../../manifests/egov-db/postgresql-pv.yaml 2>/dev/null || true

    # PVC가 Terminating 상태인 경우 강제 삭제
    if kubectl get pvc postgresql-pvc-nfs -n egov-db 2>/dev/null | grep Terminating; then
        echo -e "${YELLOW}PVC stuck in Terminating state, forcing deletion...${NC}"
        kubectl delete pvc postgresql-pvc-nfs -n egov-db --force --grace-period=0
    fi

    # PV가 Terminating 상태인 경우 강제 삭제
    if kubectl get pv postgresql-pv-nfs 2>/dev/null | grep Terminating; then
        echo -e "${YELLOW}PV stuck in Terminating state, forcing deletion...${NC}"
        kubectl patch pv postgresql-pv-nfs -p '{"metadata":{"finalizers":null}}'
        kubectl delete pv postgresql-pv-nfs --force --grace-period=0
    fi

    echo -e "\n${GREEN}PostgreSQL cleanup completed!${NC}"
}

# Redis 정리 함수
cleanup_redis() {
    echo -e "${YELLOW}Removing Redis resources...${NC}"
    kubectl delete -f ../../manifests/egov-db/redis.yaml 2>/dev/null || true

    echo -e "${GREEN}Removing Redis PV and PVC...${NC}"
    kubectl delete -f ../../manifests/egov-db/redis-pv.yaml 2>/dev/null || true

    # PVC가 Terminating 상태인 경우 강제 삭제
    if kubectl get pvc redis-pvc-nfs -n egov-db 2>/dev/null | grep Terminating; then
        echo -e "${YELLOW}PVC stuck in Terminating state, forcing deletion...${NC}"
        kubectl delete pvc redis-pvc-nfs -n egov-db --force --grace-period=0
    fi

    # PV가 Terminating 상태인 경우 강제 삭제
    if kubectl get pv redis-pv-nfs 2>/dev/null | grep Terminating; then
        echo -e "${YELLOW}PV stuck in Terminating state, forcing deletion...${NC}"
        kubectl patch pv redis-pv-nfs -p '{"metadata":{"finalizers":null}}'
        kubectl delete pv redis-pv-nfs --force --grace-period=0
    fi

    echo -e "\n${GREEN}Redis cleanup completed!${NC}"
}

# 메인 실행
echo -e "${YELLOW}Starting database cleanup...${NC}"

# MySQL 정리
cleanup_mysql

# OpenSearch 정리
cleanup_opensearch

# PostgreSQL 정리
cleanup_postgresql

# Redis 정리
cleanup_redis

# 최종 상태 확인
echo -e "\n${YELLOW}Final status check for database resources:${NC}"
echo -e "\n${GREEN}Pods in egov-db namespace:${NC}"
kubectl get pods -n egov-db
echo -e "\n${GREEN}PVCs in egov-db namespace:${NC}"
kubectl get pvc -n egov-db
echo -e "\n${GREEN}PVs related to databases:${NC}"
kubectl get pv | grep -E 'mysql|opensearch|postgresql|redis'

echo -e "\n${GREEN}Database cleanup completed!${NC}"
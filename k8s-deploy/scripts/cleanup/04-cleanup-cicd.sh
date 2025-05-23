#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 스크립트 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 에러 체크 함수
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error during $1${NC}"
        exit 1
    fi
}

# CICD 리소스 제거
echo -e "${YELLOW}Starting CICD cleanup process...${NC}"

# Jenkins 제거
echo -e "\n${YELLOW}Removing Jenkins...${NC}"
kubectl delete serviceaccount jenkins-sa -n egov-cicd --ignore-not-found=true
kubectl delete clusterrole jenkins-cluster-role --ignore-not-found=true
kubectl delete clusterrolebinding jenkins-cluster-role-binding --ignore-not-found=true
kubectl delete statefulset jenkins -n egov-cicd --ignore-not-found=true
kubectl delete service jenkins -n egov-cicd --ignore-not-found=true

# GitLab 제거
echo -e "\n${YELLOW}Removing GitLab...${NC}"
kubectl delete statefulset gitlab -n egov-cicd --ignore-not-found=true
kubectl delete service gitlab -n egov-cicd --ignore-not-found=true

# SonarQube 제거
echo -e "\n${YELLOW}Removing SonarQube...${NC}"
kubectl delete deployment sonarqube -n egov-cicd --ignore-not-found=true
kubectl delete service sonarqube -n egov-cicd --ignore-not-found=true

# Nexus 제거
echo -e "\n${YELLOW}Removing Nexus...${NC}"
kubectl delete statefulset nexus -n egov-cicd --ignore-not-found=true
kubectl delete service nexus -n egov-cicd --ignore-not-found=true

# PostgreSQL 제거
echo -e "\n${YELLOW}Removing PostgreSQL...${NC}"
kubectl delete statefulset postgresql -n egov-db --ignore-not-found=true
kubectl delete service postgresql -n egov-db --ignore-not-found=true

# Redis 제거
echo -e "\n${YELLOW}Removing Redis...${NC}"
kubectl delete statefulset redis -n egov-db --ignore-not-found=true
kubectl delete service redis -n egov-db --ignore-not-found=true

# PVC 제거
echo -e "\n${YELLOW}Removing Persistent Volume Claims...${NC}"
kubectl delete pvc -l app=jenkins -n egov-cicd --ignore-not-found=true
kubectl delete pvc -l app=gitlab -n egov-cicd --ignore-not-found=true
kubectl delete pvc -l app=nexus -n egov-cicd --ignore-not-found=true
kubectl delete pvc -l app=sonarqube -n egov-cicd --ignore-not-found=true
kubectl delete pvc -l app=postgresql -n egov-db --ignore-not-found=true
kubectl delete pvc -l app=redis -n egov-db --ignore-not-found=true

# ConfigMaps 제거
echo -e "\n${YELLOW}Removing ConfigMaps...${NC}"
kubectl delete configmap -l app=jenkins -n egov-cicd --ignore-not-found=true
kubectl delete configmap -l app=gitlab -n egov-cicd --ignore-not-found=true
kubectl delete configmap -l app=sonarqube -n egov-cicd --ignore-not-found=true

# Secrets 제거
echo -e "\n${YELLOW}Removing Secrets...${NC}"
kubectl delete secret -l app=jenkins -n egov-cicd --ignore-not-found=true
kubectl delete secret -l app=gitlab -n egov-cicd --ignore-not-found=true
kubectl delete secret -l app=sonarqube -n egov-cicd --ignore-not-found=true

# 네임스페이스 내 모든 리소스가 제거될 때까지 대기
echo -e "\n${YELLOW}Waiting for all resources to be removed...${NC}"
kubectl wait --for=delete pods --all -n egov-cicd --timeout=300s 2>/dev/null || true

# 데이터 디렉토리 정리 (선택적)
if [ -n "${DATA_BASE_PATH}" ]; then
    echo -e "\n${YELLOW}Cleaning up data directories...${NC}"
    rm -rf ${DATA_BASE_PATH}/{jenkins,gitlab,sonarqube,nexus} 2>/dev/null || true
fi

# 최종 상태 확인
echo -e "\n${YELLOW}Checking remaining resources in egov-cicd namespace:${NC}"
kubectl get all -n egov-cicd

# 네임스페이스 삭제
echo -e "\n${YELLOW}Removing namespaces...${NC}"
kubectl delete namespace egov-cicd

echo -e "\n${GREEN}CICD cleanup completed!${NC}"
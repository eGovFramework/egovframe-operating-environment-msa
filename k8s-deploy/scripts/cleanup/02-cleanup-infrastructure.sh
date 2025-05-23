#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Infrastructure 서비스 제거 (egov-infra 네임스페이스)
echo -e "${YELLOW}Removing infrastructure services...${NC}"

# Gateway Server 제거
echo -e "${GREEN}Removing Gateway Server...${NC}"
kubectl delete -f ../../manifests/egov-infra/gatewayserver-deployment.yaml 2>/dev/null || true

# RabbitMQ 관련 리소스 제거
echo -e "${GREEN}Removing RabbitMQ resources...${NC}"

echo -e "${GREEN}Removing RabbitMQ Service...${NC}"
kubectl delete -f ../../manifests/egov-infra/rabbitmq-service.yaml 2>/dev/null || true

echo -e "${GREEN}Removing RabbitMQ Deployment...${NC}"
kubectl delete -f ../../manifests/egov-infra/rabbitmq-deployment.yaml 2>/dev/null || true

echo -e "${GREEN}Removing RabbitMQ ConfigMap...${NC}"
kubectl delete -f ../../manifests/egov-infra/rabbitmq-configmap.yaml 2>/dev/null || true

echo -e "${GREEN}Removing RabbitMQ PV and PVC...${NC}"
kubectl delete -f ../../manifests/egov-infra/rabbitmq-pv.yaml 2>/dev/null || true

# PVC가 Terminating 상태인 경우 강제 삭제
if kubectl get pvc rabbitmq-pvc -n egov-infra 2>/dev/null | grep Terminating; then
    echo -e "${YELLOW}PVC stuck in Terminating state, forcing deletion...${NC}"
    kubectl delete pvc rabbitmq-pvc -n egov-infra --force --grace-period=0
fi

# PV가 Terminating 상태인 경우 강제 삭제
if kubectl get pv rabbitmq-pv 2>/dev/null | grep Terminating; then
    echo -e "${YELLOW}PV stuck in Terminating state, forcing deletion...${NC}"
    kubectl patch pv rabbitmq-pv -p '{"metadata":{"finalizers":null}}'
    kubectl delete pv rabbitmq-pv --force --grace-period=0
fi

# 리소스 제거 완료 대기
echo -e "\n${YELLOW}Waiting for resources to be terminated...${NC}"
echo -e "${YELLOW}Waiting for egov-infra resources...${NC}"
kubectl wait --for=delete pods --all -n egov-infra --timeout=60s 2>/dev/null || true

# 최종 상태 확인
echo -e "\n${YELLOW}Checking remaining resources in egov-infra:${NC}"
kubectl get all -n egov-infra

# PV/PVC 상태 확인
echo -e "\n${YELLOW}Checking remaining PV/PVC:${NC}"
echo -e "${GREEN}PVCs in egov-infra namespace:${NC}"
kubectl get pvc -n egov-infra
echo -e "\n${GREEN}PVs:${NC}"
kubectl get pv | grep rabbitmq

echo -e "\n${GREEN}Infrastructure cleanup completed!${NC}"

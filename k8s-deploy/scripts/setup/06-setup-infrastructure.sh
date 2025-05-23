#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 함수: 배포 상태 확인
check_deployment() {
    local ns=$1
    local deploy=$2
    echo -e "${YELLOW}Waiting for deployment ${deploy} in namespace ${ns}...${NC}"
    kubectl wait --for=condition=Available deployment/${deploy} -n ${ns} --timeout=30s
}

# Infrastructure 서비스 설치 (egov-infra 네임스페이스)
echo -e "${YELLOW}Installing infrastructure services...${NC}"

# RabbitMQ 설치
echo -e "${GREEN}Installing RabbitMQ...${NC}"
echo -e "${GREEN}Creating RabbitMQ ConfigMap...${NC}"
kubectl apply -f ../../manifests/egov-infra/rabbitmq-configmap.yaml

echo -e "${GREEN}Creating RabbitMQ PV and PVC...${NC}"
kubectl apply -f ../../manifests/egov-infra/rabbitmq-pv.yaml

echo -e "${GREEN}Creating RabbitMQ Deployment...${NC}"
kubectl apply -f ../../manifests/egov-infra/rabbitmq-deployment.yaml

echo -e "${GREEN}Creating RabbitMQ Service...${NC}"
kubectl apply -f ../../manifests/egov-infra/rabbitmq-service.yaml

# RabbitMQ 배포 상태 확인
check_deployment "egov-infra" "rabbitmq"

# Gateway Server 설치
echo -e "${GREEN}Installing Gateway Server...${NC}"
kubectl apply -f ../../manifests/egov-infra/gatewayserver-deployment.yaml
check_deployment "egov-infra" "gateway-server"

# 상태 확인
echo -e "\n${YELLOW}Checking infrastructure services status:${NC}"
kubectl get pods,svc -n egov-infra

# 접근 URL 출력
echo -e "\n${YELLOW}Access URLs:${NC}"
GATEWAY_PORT=$(kubectl get svc gateway-server -n egov-infra -o jsonpath='{.spec.ports[0].nodePort}')
echo -e "${GREEN}Gateway Server: http://localhost:${GATEWAY_PORT}${NC}"

RABBITMQ_AMQP_PORT=$(kubectl get svc rabbitmq -n egov-infra -o jsonpath='{.spec.ports[?(@.name=="amqp")].nodePort}')
RABBITMQ_MGT_PORT=$(kubectl get svc rabbitmq -n egov-infra -o jsonpath='{.spec.ports[?(@.name=="management")].nodePort}')
echo -e "${GREEN}RabbitMQ AMQP: localhost:${RABBITMQ_AMQP_PORT}${NC}"
echo -e "${GREEN}RabbitMQ Management UI: http://localhost:${RABBITMQ_MGT_PORT}${NC}"

echo -e "\n${GREEN}Infrastructure installation completed successfully!${NC}"

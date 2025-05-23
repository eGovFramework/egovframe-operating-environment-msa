#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수: 배포 상태 확인
check_deployment() {
    local namespace=$1
    local deployment=$2
    local max_attempts=30
    local attempt=1

    echo -e "${YELLOW}Waiting for deployment $deployment to be ready...${NC}"
    while [ $attempt -le $max_attempts ]; do
        local ready=$(kubectl get deployment $deployment -n $namespace -o jsonpath='{.status.readyReplicas}')
        if [ "$ready" == "1" ]; then
            echo -e "${GREEN}Deployment $deployment is ready${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    echo -e "${RED}Deployment $deployment failed to become ready${NC}"
    return 1
}

# 함수: HTTP 요청 테스트
test_endpoint() {
    local url=$1
    local count=${2:-1}
    local delay=${3:-1}
    
    echo -e "${YELLOW}Testing endpoint: $url${NC}"
    echo -e "${YELLOW}Making $count requests with ${delay}s delay${NC}"
    
    local success=0
    local error=0
    
    for i in $(seq 1 $count); do
        echo -e "\n${YELLOW}Request $i:${NC}"
        if curl -s -o /dev/null -w "%{http_code}" $url | grep -q "200"; then
            echo -e "${GREEN}Success${NC}"
            ((success++))
        else
            echo -e "${RED}Error${NC}"
            ((error++))
        fi
        sleep $delay
    done
    
    echo -e "\n${YELLOW}Results:${NC}"
    echo -e "Successful requests: ${GREEN}$success${NC}"
    echo -e "Failed requests: ${RED}$error${NC}"
}

# 메인 테스트 시작
echo -e "${GREEN}Starting Circuit Breaking Test...${NC}"

# 1. Error Deployment 적용
echo -e "\n${GREEN}1. Applying Error Deployment${NC}"
kubectl apply -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to apply Error Deployment${NC}"
    exit 1
fi

# 2. Deployment 준비 상태 확인
echo -e "\n${GREEN}2. Checking Deployment Status${NC}"
check_deployment "egov-app" "egov-hello-error"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error Deployment failed to become ready${NC}"
    exit 1
fi

# 3. Destination Rule 적용
echo -e "\n${GREEN}3. Applying Destination Rule${NC}"
kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to apply Destination Rule${NC}"
    exit 1
fi

# 4. Gateway Service 설정 적용
echo -e "\n${GREEN}4. Applying Gateway Service Configuration${NC}"
kubectl apply -f ../../../manifests/istio-system/gateway-service.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to apply Gateway Service configuration${NC}"
    exit 1
fi

# 5. 초기 상태 NodePort 테스트 (20회 요청)
echo -e "\n${GREEN}5. Initial Test (Ingress Gateway NodePort) - Expect mix of success and errors${NC}"
test_endpoint "http://localhost:32314/a/b/c/hello" 20 0.5

# 6. Circuit Breaker 동작 테스트 (빠른 요청 40회)
echo -e "\n${GREEN}6. Circuit Breaker Test - Circuit Open - Rapid requests, expect mostly successes${NC}"
test_endpoint "http://localhost:32314/a/b/c/hello" 40 0.5

# 7. Circuit 다시 Closed 상태 확인 (60초 후 20회 요청)
echo -e "\n${GREEN}7. Waiting 1 minute for circuit to potentially close again...${NC}"
sleep 60
echo -e "\n${GREEN}Testing after wait - Expect mix of success and errors${NC}"
test_endpoint "http://localhost:32314/a/b/c/hello" 20 0.5

# 11. 상태 출력
echo -e "\n${GREEN}8. Current System Status${NC}"
echo -e "\n${YELLOW}Pods:${NC}"
kubectl get pods -n egov-app -l app=egov-hello
echo -e "\n${YELLOW}Destination Rule:${NC}"
kubectl get destinationrule -n egov-app egov-hello -o yaml

echo -e "\n${GREEN}Circuit Breaking Test Complete${NC}"
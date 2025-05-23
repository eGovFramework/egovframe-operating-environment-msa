#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

configure_gateway_service() {
    echo -e "${GREEN}Applying Gateway Service Configuration${NC}"
    kubectl apply -f ../../../manifests/istio-system/gateway.yaml
    kubectl apply -f ../../../manifests/istio-system/gateway-service.yaml
    echo -e "${GREEN}Gateway Service configuration applied successfully${NC}"
}

# 함수: 상태 체크
check_deployment() {
    local namespace=$1
    local deployment_name=$2
    echo -e "\nWaiting for deployment $deployment_name to be ready..."
    kubectl wait --for=condition=Available deployment/$deployment_name -n $namespace --timeout=300s
    return $?
}

# 함수: 테스트 요청 전송
send_test_requests() {
    local count=$1
    local url="http://localhost:32314/a/b/c/hello"
    
    echo -e "\n${YELLOW}Sending $count test requests...${NC}"
    for i in $(seq 1 $count); do
        echo -e "\n${YELLOW}Request $i of $count${NC}"
        response=$(curl -s -w "\n%{http_code}" $url)
        http_code=$(echo "$response" | tail -n1)
        content=$(echo "$response" | sed \$d)
        
        echo -e "${GREEN}Response (HTTP $http_code): $content${NC}"
        sleep 1
    done
}

# 메인 테스트 시작
echo -e "${GREEN}Starting Blue-Green Release Test...${NC}"

# 0. Gateway Service 설정 적용
configure_gateway_service

# 1. Blue(현재) 버전 확인
echo -e "\n${GREEN}1. Checking Current Blue Version${NC}"
kubectl get deployment -n egov-app egov-hello -o wide
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to get Blue deployment${NC}"
    exit 1
fi

# 2. Green(새) 버전 배포
echo -e "\n${GREEN}2. Deploying Green Version${NC}"
kubectl apply -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to apply Green deployment${NC}"
    exit 1
fi

# 3. Deployment 준비 상태 확인
echo -e "\n${GREEN}3. Checking Deployments Status${NC}"
check_deployment "egov-app" "egov-hello"        # Blue
check_deployment "egov-app" "egov-hello-error"  # Green

# 4. Destination Rule 적용
echo -e "\n${GREEN}4. Applying Destination Rule${NC}"
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  host: egov-hello
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
  subsets:
  - name: blue
    labels:
      variant: normal
  - name: green
    labels:
      variant: error
EOF

# 5. Virtual Service 적용 (초기 상태 - Blue로 100% 라우팅)
echo -e "\n${GREEN}5. Applying Virtual Service (Initial Blue Route)${NC}"
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  hosts:
  - "*"
  gateways:
  - istio-system/istio-ingressgateway
  http:
  - match:
    - uri:
        prefix: /a/b/c/hello
    route:
    - destination:
        host: egov-hello
        subset: blue
        port:
          number: 80
EOF

# 6. Blue 버전 테스트
echo -e "\n${GREEN}6. Testing Blue Version${NC}"
send_test_requests 5

# 7. Green 버전으로 전환
echo -e "\n${GREEN}7. Switching Traffic to Green Version${NC}"
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  hosts:
  - "*"
  gateways:
  - istio-system/istio-ingressgateway
  http:
  - match:
    - uri:
        prefix: /a/b/c/hello
    route:
    - destination:
        host: egov-hello
        subset: green
        port:
          number: 80
EOF

# 8. Green 버전 테스트
echo -e "\n${GREEN}8. Testing Green Version${NC}"
send_test_requests 5

# 9. 로그 확인
echo -e "\n${GREEN}9. Checking Logs${NC}"
echo -e "\n${YELLOW}Blue Version Logs:${NC}"
kubectl logs -l variant=normal -c egov-hello -n egov-app --tail=10

echo -e "\n${YELLOW}Green Version Logs:${NC}"
kubectl logs -l variant=error -c egov-hello -n egov-app --tail=10

# 10. 롤백 절차 안내
echo -e "\n${GREEN}Blue-Green Release Test Completed${NC}"
echo "Notes:"
echo "1. Green version is now receiving 100% of traffic"
echo "2. To rollback to Blue version:"
cat << 'EOF'
kubectl apply -f - << 'INNEREOF'
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  hosts:
  - "*"
  gateways:
  - istio-system/istio-ingressgateway
  http:
  - match:
    - uri:
        prefix: /a/b/c/hello
    route:
    - destination:
        host: egov-hello
        subset: blue
        port:
          number: 80
INNEREOF
EOF

echo "3. To clean up after successful deployment:"
echo "   kubectl delete -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml"
echo "   kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml"
echo "   kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml"
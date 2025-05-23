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
echo -e "${GREEN}Starting Canary Release Test...${NC}"

# 0. Gateway Service 설정 적용
configure_gateway_service

# 1. v2 (Canary) Deployment 적용
echo -e "\n${GREEN}1. Applying v2 (Canary) Deployment${NC}"
kubectl apply -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to apply v2 Deployment${NC}"
    exit 1
fi

# 2. Deployment 준비 상태 확인
echo -e "\n${GREEN}2. Checking Deployments Status${NC}"
check_deployment "egov-app" "egov-hello"
check_deployment "egov-app" "egov-hello-error"

# 3. Destination Rule 적용
echo -e "\n${GREEN}3. Applying Destination Rule${NC}"
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
  - name: v1
    labels:
      variant: normal
  - name: v2
    labels:
      variant: error
EOF

# 4. Virtual Service 적용 (초기 90:10 비율)
echo -e "\n${GREEN}4. Applying Virtual Service with Initial Traffic Split (90:10)${NC}"
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
        subset: v1
        port:
          number: 80
      weight: 90
    - destination:
        host: egov-hello
        subset: v2
        port:
          number: 80
      weight: 10
EOF

# 5. 초기 트래픽 분배 테스트 (90:10)
echo -e "\n${GREEN}5. Testing Initial Traffic Split (90:10)${NC}"
send_test_requests 20

# 6. Virtual Service 업데이트 (75:25 비율)
echo -e "\n${GREEN}6. Updating Traffic Split (75:25)${NC}"
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
        subset: v1
        port:
          number: 80
      weight: 75
    - destination:
        host: egov-hello
        subset: v2
        port:
          number: 80
      weight: 25
EOF

# 7. 업데이트된 트래픽 분배 테스트 (75:25)
echo -e "\n${GREEN}7. Testing Updated Traffic Split (75:25)${NC}"
send_test_requests 20

# 8. 로그 확인
echo -e "\n${GREEN}8. Checking Logs${NC}"
echo -e "\n${YELLOW}v1 Pod Logs:${NC}"
kubectl logs -l version=v1 -c egov-hello -n egov-app --tail=10

echo -e "\n${YELLOW}v2 Pod Logs:${NC}"
kubectl logs -l version=v2 -c egov-hello -n egov-app --tail=10

echo -e "\n${GREEN}Canary Release Test Completed${NC}"
echo "Notes:"
echo "1. Check that requests are distributed according to the specified weights"
echo "2. Monitor both versions for errors and performance"
echo "3. To clean up:"
echo "   kubectl delete -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml"
echo "   kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml"
echo "   kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml"
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
echo -e "${GREEN}Starting Mirroring Test...${NC}"

# 0. Gateway Service 설정 적용
configure_gateway_service

# 1. Error Deployment 적용
echo -e "\n${GREEN}1. Applying Error Deployment${NC}"
kubectl apply -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to apply Error Deployment${NC}"
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
    outlierDetection:       # Circuit Breaking 설정
      interval: 1s         # 장애 감지 주기. 매 3초마다 스캔하여 밖으로 내보낼 인스턴스를 찾는다
      consecutive5xxErrors: 3  # 연속적으로 오류가 발생할 때 제외되는 오류 횟수. 연속적으로 5xx 에러가 3번 발생하면, 해당 인스턴스를 제외
      baseEjectionTime: 30s  # 인스턴스가 트래픽에서 제외되는 기본 시간. 1분 동안 배제(=Circuit Open) 처리
      maxEjectionPercent: 100 # 최대 100%까지 Pod 제외 가능
  subsets:
  - name: v1
    labels:
      variant: normal
  - name: v2
    labels:
      variant: error
EOF

# 4. Virtual Service 적용
echo -e "\n${GREEN}4. Applying Virtual Service with Mirroring${NC}"
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
    mirror:
      host: egov-hello
      subset: v2
    mirrorPercentage:
      value: 100
EOF

# 5. 테스트 요청 전송
echo -e "\n${GREEN}5. Testing Mirroring Configuration${NC}"
send_test_requests 20

# 6. 로그 확인
echo -e "\n${GREEN}6. Checking Logs${NC}"
echo -e "\n${YELLOW}Normal Pod Logs:${NC}"
kubectl logs -l variant=normal -c egov-hello -n egov-app --tail=10

echo -e "\n${YELLOW}Error Pod Logs:${NC}"
kubectl logs -l variant=error -c egov-hello -n egov-app --tail=10

echo -e "\n${GREEN}Mirroring Test Completed${NC}"
echo "Notes:"
echo "1. Check that requests appear in both normal and error pod logs"
echo "2. Only responses from normal pods should have been returned to the client"
echo "3. To clean up:"
echo "   kubectl delete -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml"
echo "   kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml"
echo "   kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml"
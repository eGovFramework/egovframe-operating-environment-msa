#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 함수: 테스트 요청 전송
send_test_requests() {
    local count=$1
    local url="http://localhost:32314/a/b/c/hello"
    
    echo -e "\n${YELLOW}Sending $count test requests...${NC}"
    for i in $(seq 1 $count); do
        echo -e "\n${YELLOW}Request $i of $count${NC}"
        start_time=$(date +%s.%N)
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" $url)
        http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d':' -f2)
        time_total=$(echo "$response" | grep "TIME:" | cut -d':' -f2)
        content=$(echo "$response" | grep -v "HTTP_CODE:" | grep -v "TIME:")
        
        echo -e "${GREEN}Response (HTTP $http_code) in ${time_total}s: $content${NC}"
        sleep 1
    done
}

# 함수: Virtual Service 적용
apply_virtual_service() {
    local fault_type=$1
    echo -e "\n${GREEN}Applying Virtual Service with $fault_type fault injection${NC}"
    
    case $fault_type in
        "delay")
            cat << EOF | kubectl apply -f -
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
    fault:
      delay:
        percentage:
          value: 100
        fixedDelay: 5s
    route:
    - destination:
        host: egov-hello
        port:
          number: 80
EOF
            ;;
            
        "abort")
            cat << EOF | kubectl apply -f -
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
    fault:
      abort:
        percentage:
          value: 100
        httpStatus: 500
    route:
    - destination:
        host: egov-hello
        port:
          number: 80
EOF
            ;;
            
        "mixed")
            cat << EOF | kubectl apply -f -
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
    fault:
      delay:
        percentage:
          value: 50
        fixedDelay: 5s
      abort:
        percentage:
          value: 50
        httpStatus: 500
    route:
    - destination:
        host: egov-hello
        port:
          number: 80
EOF
            ;;
    esac
}

# 메인 테스트 시작
echo -e "${GREEN}Starting Fault Injection Test...${NC}"

# 1. 지연 주입 테스트
echo -e "\n${GREEN}1. Testing Delay Injection${NC}"
apply_virtual_service "delay"
echo -e "${YELLOW}Sending requests with 5s delay...${NC}"
send_test_requests 5

# 2. 오류 주입 테스트
echo -e "\n${GREEN}2. Testing Abort Injection${NC}"
apply_virtual_service "abort"
echo -e "${YELLOW}Sending requests with HTTP 500...${NC}"
send_test_requests 5

# 3. 혼합 장애 테스트
echo -e "\n${GREEN}3. Testing Mixed Fault Injection${NC}"
apply_virtual_service "mixed"
echo -e "${YELLOW}Sending requests with mixed faults...${NC}"
send_test_requests 10

# 4. 원래 설정 복구
echo -e "\n${GREEN}4. Restoring original configuration${NC}"
kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml

echo -e "\n${GREEN}Fault Injection Test Completed${NC}"
echo "Notes:"
echo "1. Delay Test: All requests should have taken at least 5 seconds"
echo "2. Abort Test: All requests should have returned HTTP 500"
echo "3. Mixed Test: ~50% delays and ~50% HTTP 500s"
echo "4. Original configuration has been restored"
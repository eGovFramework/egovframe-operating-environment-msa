#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

configure_gateway_service() {
    echo -e "${GREEN}Applying Gateway Service Configuration${NC}"
    kubectl apply -f ../../../manifests/istio-system/gateway.yaml
    kubectl apply -f ../../../manifests/istio-system/gateway-service.yaml
    kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml
    kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml
    echo -e "${GREEN}Gateway Service configuration applied successfully${NC}"
}

# 함수: 서비스 상태 확인
check_service() {
    local namespace=$1
    local service=$2
    echo -e "${YELLOW}Checking service $service in namespace $namespace...${NC}"
    kubectl get svc $service -n $namespace
}

# 함수: 파드 상태 확인
check_pods() {
    local namespace=$1
    local label=$2
    echo -e "${YELLOW}Checking pods with label $label in namespace $namespace...${NC}"
    kubectl get pods -n $namespace -l $label
}

# 함수: HTTP 요청 테스트
test_endpoint() {
    local url=$1
    local attempts=${2:-1}
    
    echo -e "${YELLOW}Testing endpoint: $url${NC}"
    for i in $(seq 1 $attempts); do
        echo -e "${YELLOW}Request $i:${NC}"
        curl -s $url
        echo
    done
}

# 메인 테스트 시작
echo -e "${GREEN}Starting Load Balancing and Port Forward Test...${NC}"

# 0. Gateway Service 설정 적용
configure_gateway_service

# 1. Istio Ingress Gateway 상태 확인
echo -e "\n${GREEN}1. Checking Istio Ingress Gateway Status${NC}"
check_service "istio-system" "istio-ingressgateway"

# 2. Virtual Service 상태 확인
echo -e "\n${GREEN}2. Checking Virtual Service Status${NC}"
kubectl get virtualservice -n egov-app

# 3. egov-hello 서비스 및 파드 상태 확인
echo -e "\n${GREEN}3. Checking egov-hello Service and Pods${NC}"
check_pods "egov-app" "app=egov-hello"

# 4. 라우팅 설정 확인
echo -e "\n${GREEN}4. Checking Routing Configuration${NC}"
istioctl proxy-config routes deploy/istio-ingressgateway -n istio-system

# 5. 내부 서비스 테스트
echo -e "\n${GREEN}5. Testing Internal Service Access${NC}"
kubectl run -i --rm --restart=Never curl-test --image=curlimages/curl -- curl http://egov-hello.egov-app/a/b/c/hello

# 6. 외부 접근 테스트 (다양한 포트)
echo -e "\n${GREEN}6. Testing External Access${NC}"

# 7. Gateway Server로 테스트
echo -e "\n${YELLOW}Testing Gateway Server Port 9000:${NC}"
test_endpoint "http://localhost:9000/a/b/c/hello" 4

# Istio Ingress Gateway NodePort 테스트
echo -e "\n${YELLOW}Testing Istio Ingress Gateway NodePort 32314:${NC}"
test_endpoint "http://localhost:32314/a/b/c/hello" 4

# 3. 각 Pod의 최근 로그 확인
echo -e "\n${GREEN}Recent logs from all pods:${NC}"
kubectl get pods -n egov-app -l app=egov-hello -o name | while read pod; do
    echo -e "\n${YELLOW}Logs from $pod:${NC}"
    kubectl logs $pod -n egov-app --tail=20
done

# 결과 요약
echo -e "\n${GREEN}Test Summary:${NC}"
echo -e "1. Istio Ingress Gateway: NodePort HTTP(80:$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}'))"
echo -e "2. Virtual Services: $(kubectl get virtualservice -n egov-app -o jsonpath='{.items[*].metadata.name}')"
echo -e "3. Istio Ingress Gateway 뿐 아니라 Gateway Server도 Destination Rule를 통해 로드밸런싱이 적용됩니다."

echo -e "\n${YELLOW}로드밸런싱 상세 확인 방법:${NC}"
echo -e "1. Kiali UI (http://localhost:30001)"
echo -e "   - Services > egov-hello > Endpoints 확인"
echo -e "2. Jaeger UI (http://localhost:30002)"
echo -e "   - Operation "egov-hello.egov-app:80" 로 검색"
echo -e "   -  각 Trace 의 Span Attributes의 net.sock.host.addr 값 확인"

exit 0

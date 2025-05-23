#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수: 테스트 시작 전 상태 확인
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # AlertManager 상태 확인
    if ! kubectl get pods -n egov-monitoring -l app=alertmanager | grep -q "Running"; then
        echo -e "${RED}AlertManager is not running${NC}"
        return 1
    fi
    
    # Prometheus 상태 확인
    if ! kubectl get pods -n egov-monitoring -l app.kubernetes.io/name=prometheus | grep -q "Running"; then
        echo -e "${RED}Prometheus is not running${NC}"
        return 1
    fi
    
    # egov-hello-error 상태 확인
    if ! kubectl get deployment egov-hello-error -n egov-app >/dev/null 2>&1; then
        echo -e "${RED}egov-hello-error deployment not found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}All prerequisites are met${NC}"
    return 0
}

# 함수: 에러 요청 생성
generate_error_requests() {
    local url="http://localhost:32314/a/b/c/hello"
    local count=30  # 충분한 에러를 발생시키기 위해 30회로 설정
    local errors=0
    
    echo -e "\n${YELLOW}Generating $count requests to trigger circuit breaker...${NC}"
    
    for i in $(seq 1 $count); do
        echo -e "\n${YELLOW}Request $i of $count${NC}"
        response=$(curl -s -w "\n%{http_code}" $url)
        http_code=$(echo "$response" | tail -n1)
        content=$(echo "$response" | sed \$d)
        
        if [[ "$http_code" =~ ^5 ]]; then
            ((errors++))
            echo -e "${RED}Error response (HTTP $http_code)${NC}"
            echo -e "${RED}Response: $content${NC}"
        else
            echo -e "${GREEN}Success response (HTTP $http_code)${NC}"
            echo -e "${GREEN}Response: $content${NC}"
        fi
        sleep 1  # 1초 간격으로 요청
    done
    
    echo -e "\n${YELLOW}Error generation summary:${NC}"
    echo -e "Total requests: $count"
    echo -e "Error responses: ${RED}$errors${NC}"
}

# 함수: 알림 상태 확인
check_alerts() {
    echo -e "${YELLOW}Checking alerts in AlertManager...${NC}"
    curl -s http://localhost:9093/api/v1/alerts | jq .
}

# AlertManager 연결 테스트 함수
check_alertmanager_connection() {
    echo -e "${YELLOW}Testing AlertManager connection...${NC}"
    response=$(curl -s -w "\n%{http_code}" http://localhost:9093/-/healthy)
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}AlertManager is healthy${NC}"
        return 0
    else
        echo -e "${RED}AlertManager connection failed${NC}"
        return 1
    fi
}

# 함수: Destination Rule 설정 변경
update_destination_rule() {
    echo -e "${YELLOW}Updating Destination Rule for testing...${NC}"
    
    # 임시 파일 생성
    cat << EOF > /tmp/destination-rule-test.yaml
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
    outlierDetection:
      interval: 3s           # 더 긴 간격으로 검사
      consecutive5xxErrors: 5  # 더 많은 오류 허용
      baseEjectionTime: 30s   # 짧은 ejection 시간
      maxEjectionPercent: 50  # 절반만 ejection
EOF

    # Destination Rule 적용
    kubectl apply -f /tmp/destination-rule-test.yaml
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Destination Rule updated successfully${NC}"
    else
        echo -e "${RED}Failed to update Destination Rule${NC}"
        return 1
    fi

    # 임시 파일 삭제
    rm /tmp/destination-rule-test.yaml
}

# 함수: 원래 Destination Rule 복원
restore_destination_rule() {
    echo -e "${YELLOW}Restoring original Destination Rule...${NC}"
    kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Original Destination Rule restored successfully${NC}"
    else
        echo -e "${RED}Failed to restore original Destination Rule${NC}"
        return 1
    fi
}

# 메인 스크립트 시작
echo -e "${GREEN}Starting Alert Notification Test...${NC}"

# 1. 사전 조건 확인
echo -e "\n${GREEN}1. Checking Prerequisites${NC}"
check_prerequisites || exit 1

# 2. Destination Rule 설정 변경
echo -e "\n${GREEN}2. Updating Destination Rule Configuration${NC}"
update_destination_rule || exit 1

# 3. 기존 포트포워딩 정리
echo -e "\n${GREEN}3. Cleaning up existing port-forwards${NC}"
pkill -f "port-forward.*alertmanager" || true
sleep 2

# 4. 필요한 포트포워딩 설정
echo -e "\n${GREEN}4. Setting up port-forwards${NC}"
kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093 &
sleep 5
check_alertmanager_connection || exit 1

# 5. 현재 알림 상태 확인
echo -e "\n${GREEN}5. Checking current alert status${NC}"
check_alerts

# 6. 에러 요청 생성 (3회 반복)
echo -e "\n${GREEN}6. Generating error requests${NC}"
for i in {1..3}; do
    echo -e "\n${YELLOW}Test iteration $i of 3${NC}"
    generate_error_requests
    sleep 5
done

# 7. 알림 발생 대기
echo -e "\n${GREEN}7. Waiting for alerts to be generated...${NC}"
echo -e "${YELLOW}   - Prometheus rule evaluation: ~10s${NC}"
echo -e "${YELLOW}   - AlertManager grouping: ~10s${NC}"
echo -e "${YELLOW}   - Alert notification delay: ~10s${NC}"
sleep 30

# 8. 알림 상태 재확인
echo -e "\n${GREEN}8. Checking final alert status${NC}"
check_alerts

# 9. 원래 Destination Rule 복원
echo -e "\n${GREEN}9. Restoring original configuration${NC}"
restore_destination_rule

# 10. 정리
echo -e "\n${GREEN}10. Cleanup${NC}"
pkill -f "port-forward.*alertmanager" || true

echo -e "\n${GREEN}Alert Notification Test Complete!${NC}"
echo -e "${YELLOW}Please check your Slack channel '#egovalertmanager' for notifications${NC}"
echo -e "${YELLOW}To check alerts in AlertManager UI:${NC}"
echo -e "${YELLOW}1. Run: kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093${NC}"
echo -e "${YELLOW}2. Open: http://localhost:9093/#/alerts${NC}"

exit 0

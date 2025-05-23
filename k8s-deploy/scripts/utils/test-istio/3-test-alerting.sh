#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수: AlertManager 상태 확인
check_alertmanager() {
    echo -e "${YELLOW}Checking AlertManager status...${NC}"
    
    # Circuit Breaker 알림 규칙 ConfigMap 확인 및 적용
    if ! kubectl get configmap prometheus-rules -n egov-monitoring &>/dev/null; then
        echo -e "${YELLOW}Creating Circuit Breaker alert rules...${NC}"
        kubectl apply -f ../../manifests/egov-monitoring/circuit-breaker-alerts-configmap.yaml || {
            echo -e "${RED}Failed to create Circuit Breaker alert rules${NC}"
            return 1
        }
        
        # Prometheus 재시작하여 새 규칙 적용
        echo -e "${YELLOW}Restarting Prometheus to apply new rules...${NC}"
        kubectl rollout restart deployment prometheus -n egov-monitoring
        
        # Prometheus 재시작 완료 대기
        echo -e "${YELLOW}Waiting for Prometheus to be ready...${NC}"
        kubectl rollout status deployment prometheus -n egov-monitoring --timeout=300s || {
            echo -e "${RED}Failed to restart Prometheus${NC}"
            return 1
        }
    fi

    # AlertManager 실행 상태 확인
    if ! kubectl get pods -n egov-monitoring -l app=alertmanager | grep -q "Running"; then
        echo -e "${RED}AlertManager is not running. Attempting to start...${NC}"
        
        # AlertManager 설정이 있는지 확인
        if ! kubectl get secret alertmanager-config -n egov-monitoring &>/dev/null; then
            echo -e "${YELLOW}Creating AlertManager configuration...${NC}"
            kubectl apply -f ../../manifests/egov-monitoring/alertmanager-config.yaml || {
                echo -e "${RED}Failed to create AlertManager configuration${NC}"
                return 1
            }
        fi
        
        # AlertManager 배포
        echo -e "${YELLOW}Deploying AlertManager...${NC}"
        kubectl apply -f ../../manifests/egov-monitoring/alertmanager.yaml || {
            echo -e "${RED}Failed to deploy AlertManager${NC}"
            return 1
        }
        
        # Pod가 Ready 상태가 될 때까지 대기
        echo -e "${YELLOW}Waiting for AlertManager to be ready...${NC}"
        if ! kubectl wait --for=condition=Ready pods -l app=alertmanager -n egov-monitoring --timeout=300s; then
            echo -e "${RED}Failed to start AlertManager${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}AlertManager and alert rules are properly configured and running${NC}"
    return 0
}

# 함수: 포트 사용 확인
check_port() {
    local port=$1
    if lsof -i :$port > /dev/null 2>&1; then
        echo -e "${RED}Port $port is already in use${NC}"
        return 1
    fi
    echo -e "${GREEN}Port $port is available${NC}"
    return 0
}

# 함수: 테스트 알림 전송
send_test_alert() {
    local port=$1
    echo -e "${YELLOW}Sending test alert...${NC}"
    
    response=$(curl -s -w "\n%{http_code}" -H "Content-Type: application/json" -d '[{
        "labels": {
            "alertname": "TestAlert",
            "service": "test-service",
            "severity": "critical"
        },
        "annotations": {
            "summary": "Test Alert",
            "description": "This is a test alert"
        }
    }]' http://localhost:$port/api/v1/alerts)
    
    http_code=$(echo "$response" | tail -n1)
    content=$(echo "$response" | sed \$d)
    
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}Alert sent successfully${NC}"
        echo -e "${GREEN}Response: $content${NC}"
        return 0
    else
        echo -e "${RED}Failed to send alert${NC}"
        echo -e "${RED}Response: $content${NC}"
        return 1
    fi
}

# 메인 테스트 시작
echo -e "${GREEN}Starting AlertManager Test...${NC}"

# 1. AlertManager 상태 확인
echo -e "\n${GREEN}1. Checking AlertManager Status${NC}"
check_alertmanager || exit 1

# 2. 기존 포트포워딩 프로세스 종료
echo -e "\n${GREEN}2. Cleaning up existing port-forwards${NC}"
pkill -f "port-forward.*alertmanager" || true
sleep 2

# 3. 포트 사용 확인
echo -e "\n${GREEN}3. Checking port availability${NC}"
check_port 9093 || exit 1

# 4. AlertManager 포트포워딩
echo -e "\n${GREEN}4. Setting up port-forward${NC}"
kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093 &
echo -e "${YELLOW}Waiting for port-forward to be ready...${NC}"
sleep 5

# 5. AlertManager 연결 테스트
echo -e "\n${GREEN}5. Testing AlertManager connection${NC}"
if ! curl -s http://localhost:9093/-/healthy > /dev/null; then
    echo -e "${RED}Failed to connect to AlertManager${NC}"
    exit 1
fi
echo -e "${GREEN}Successfully connected to AlertManager${NC}"

# 6. 테스트 알림 전송
echo -e "\n${GREEN}6. Sending test alert${NC}"
send_test_alert 9093 || exit 1

# 7. AlertManager 설정 확인
echo -e "\n${GREEN}7. Checking AlertManager configuration${NC}"
echo -e "${YELLOW}AlertManager config:${NC}"
kubectl get secret alertmanager-config -n egov-monitoring -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d

# 8. 정리
echo -e "\n${GREEN}8. Cleanup${NC}"
pkill -f "port-forward.*alertmanager" || true

echo -e "\n${GREEN}AlertManager Test Complete!${NC}"
echo -e "${YELLOW}Please check your Slack channel '#alerts' for the test notification${NC}"

exit 0

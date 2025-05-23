#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}=== Access Information ===${NC}"

# 모니터링 도구 접근 정보
echo -e "\n${BLUE}[Monitoring Tools]${NC}"
echo -e "${GREEN}1. Monitoring Service URLs:${NC}"
echo "- Kiali:        http://localhost:30001"
echo "- Grafana:      http://localhost:30002"
echo "- Jaeger:       http://localhost:30003"
echo "- Prometheus:   http://localhost:30004"
echo "- AlertManager: http://localhost:9093 (requires port-forward)"

echo -e "\n${GREEN}Default Credentials:${NC}"
echo "- Grafana: admin/admin (초기 접속 시 비밀번호 변경 필요)"
echo "- Kiali:   admin/admin"

echo -e "\n${GREEN}AlertManager Access:${NC}"
echo "kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093"

# CICD 접근 정보
echo -e "\n${BLUE}[CICD]${NC}"
echo -e "${GREEN}1. Jenkins:${NC}"
echo "- Web UI: http://localhost:30011"

# 데이터베이스 접근 정보
echo -e "\n${BLUE}[Databases]${NC}"
echo -e "${GREEN}1. MySQL:${NC}"
echo "- Service: localhost:30306"
echo "- Credentials: com/com01, root/root"

echo -e "\n${GREEN}2. OpenSearch Dashboard:${NC}"
echo "- Service:    http://localhost:30561"

# 인프라 서비스 접근 정보
echo -e "\n${BLUE}[Infrastructure Services]${NC}"
echo -e "${GREEN}1. Gateway Server:${NC}"
echo "- External: http://localhost:9000"

echo -e "\n${GREEN}2. RabbitMQ:${NC}"
echo "- Management UI: http://localhost:31672"
echo "- Credentials: guest/guest"

# 애플리케이션 서비스 접근 정보
echo -e "\n${BLUE}[Application Services]${NC}"
echo "All services are accessible through Gateway Server (http://localhost:9000)"
echo -e "${GREEN}Available Endpoints:${NC}"
echo "- /egov-main          - Main Service"
echo "- /egov-board         - Board Service"
echo "- /egov-login         - Login Service"
echo "- /egov-author        - Author Service"
echo "- /egov-mobileid      - Mobile ID Service"
echo "- /egov-questionnaire - Questionnaire Service"
echo "- /egov-cmmncode      - Common Code Service"
echo "- /egov-search        - Search Service"
echo "- /egov-hello         - Hello World Service (http://localhost:9000/a/b/c/hello)"

# 상태 확인 명령어
echo -e "\n${BLUE}[Health Check Commands]${NC}"
echo -e "${GREEN}1. Check All Pods:${NC}"
echo "kubectl get pods --all-namespaces"

echo -e "\n${GREEN}2. Check Services by Namespace:${NC}"
echo "- Monitoring:    kubectl get pods,svc -n egov-monitoring"
echo "- Database:      kubectl get pods,svc -n egov-db"
echo "- Infrastructure: kubectl get pods,svc -n egov-infra"
echo "- Applications:   kubectl get pods,svc -n egov-app"

echo -e "\n${GREEN}3. View Logs:${NC}"
echo "kubectl logs -f <pod-name> -n <namespace>"

echo -e "\n${GREEN}4. Port-forward Helper:${NC}"
echo "kubectl port-forward svc/<service-name> -n <namespace> <local-port>:<service-port>"

echo -e "\n${YELLOW}Note: Make sure the Kubernetes cluster is running and accessible before using these commands.${NC}"
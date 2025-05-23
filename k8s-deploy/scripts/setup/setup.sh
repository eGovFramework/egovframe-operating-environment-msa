#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 현재 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Kubernetes 클러스터 상태 확인 함수
check_kubernetes() {
    echo -e "${YELLOW}Checking Kubernetes cluster status...${NC}"
    
    # kubectl 명령어 존재 확인
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}kubectl command not found. Please install kubectl first.${NC}"
        return 1
    fi
    
    # Kubernetes 클러스터 연결 상태 확인
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Unable to connect to Kubernetes cluster.${NC}"
        echo -e "${YELLOW}Please check if:${NC}"
        echo "1. Kubernetes cluster is running (e.g., Docker Desktop, minikube, or other cluster)"
        echo "2. kubectl is properly configured"
        echo "3. You have proper permissions"
        echo -e "\nRun 'kubectl cluster-info' for more details."
        return 1
    fi
    
    echo -e "${GREEN}Kubernetes cluster is running and accessible${NC}"
    
    # 현재 컨텍스트 출력
    echo -e "${YELLOW}Current context:${NC}"
    kubectl config current-context
    
    return 0
}

# 실행 권한 확인 및 부여
chmod +x ${SCRIPT_DIR}/*.sh

# Kubernetes 클러스터 상태 확인
if ! check_kubernetes; then
    exit 1
fi

# 함수: 오류 체크
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error occurred in $1${NC}"
        exit 1
    fi
}

# 함수: Istio 설치 확인
check_istio() {
    echo -e "${YELLOW}Verifying Istio installation...${NC}"
    
    # 네임스페이스 확인
    if ! kubectl get namespace istio-system >/dev/null 2>&1; then
        echo -e "${RED}Istio namespace not found${NC}"
        return 1
    fi
    
    # Pod 상태 확인
    if ! kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s; then
        echo -e "${RED}Istio pods are not ready${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Istio installation verified successfully${NC}"
    return 0
}

# 함수: 네임스페이스 설치 확인
check_namespaces() {
    echo -e "${YELLOW}Verifying namespaces...${NC}"
    local namespaces=("egov-infra" "egov-app" "egov-db" "egov-monitoring")
    
    for ns in "${namespaces[@]}"; do
        if ! kubectl get namespace ${ns} >/dev/null 2>&1; then
            echo -e "${RED}Namespace ${ns} not found${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}Namespaces verified successfully${NC}"
    return 0
}

# 함수: 모니터링 설치 확인
check_monitoring() {
    echo -e "${YELLOW}Verifying monitoring installation...${NC}"
    local services=("prometheus" "grafana" "kiali" "jaeger")
    
    for svc in "${services[@]}"; do
        if ! kubectl get deployment ${svc} -n egov-monitoring >/dev/null 2>&1; then
            echo -e "${RED}Monitoring service ${svc} not found${NC}"
            return 1
        fi
    done
    
    if ! kubectl wait --for=condition=Ready pods --all -n egov-monitoring --timeout=300s; then
        echo -e "${RED}Monitoring pods are not ready${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Monitoring installation verified successfully${NC}"
    return 0
}

# 함수: MySQL 설치 확인
check_mysql() {
    echo -e "${YELLOW}Verifying MySQL installation...${NC}"
    if ! kubectl get statefulset mysql -n egov-db >/dev/null 2>&1; then
        echo -e "${RED}MySQL statefulset not found${NC}"
        return 1
    fi
    
    if ! kubectl wait --for=condition=Ready pods -l app=mysql -n egov-db --timeout=300s; then
        echo -e "${RED}MySQL pod is not ready${NC}"
        return 1
    fi
    
    echo -e "${GREEN}MySQL installation verified successfully${NC}"
    return 0
}

# 함수: OpenSearch 설치 확인
check_opensearch() {
    echo -e "${YELLOW}Verifying OpenSearch installation...${NC}"
    if ! kubectl get statefulset opensearch -n egov-db >/dev/null 2>&1; then
        echo -e "${RED}OpenSearch statefulset not found${NC}"
        return 1
    fi
    
    if ! kubectl wait --for=condition=Ready pods -l app=opensearch -n egov-db --timeout=300s; then
        echo -e "${RED}OpenSearch pods are not ready${NC}"
        return 1
    fi
    
    echo -e "${GREEN}OpenSearch installation verified successfully${NC}"
    return 0
}

# 함수: 인프라 설치 확인
check_infrastructure() {
    echo -e "${YELLOW}Verifying infrastructure installation...${NC}"
    local services=("gateway-server" "rabbitmq")
    
    for svc in "${services[@]}"; do
        if ! kubectl get deployment ${svc} -n egov-infra >/dev/null 2>&1; then
            echo -e "${RED}Infrastructure service ${svc} not found${NC}"
            return 1
        fi
    done
    
    if ! kubectl wait --for=condition=Ready pods --all -n egov-infra --timeout=300s; then
        echo -e "${RED}Infrastructure pods are not ready${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Infrastructure installation verified successfully${NC}"
    return 0
}

# 함수: 애플리케이션 설치 확인
check_applications() {
    echo -e "${YELLOW}Verifying application installation...${NC}"
    local apps=("egov-main" "egov-board" "egov-login" "egov-author" "egov-mobileid" "egov-questionnaire" "egov-cmmncode" "egov-search")
    
    for app in "${apps[@]}"; do
        if ! kubectl get deployment ${app} -n egov-app >/dev/null 2>&1; then
            echo -e "${RED}Application ${app} not found${NC}"
            return 1
        fi
    done
    
    if ! kubectl wait --for=condition=Ready pods --all -n egov-app --timeout=300s; then
        echo -e "${RED}Application pods are not ready${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Applications installation verified successfully${NC}"
    return 0
}

# PostgreSQL 설치 확인 함수 추가
check_postgresql() {
    echo -e "${YELLOW}Verifying PostgreSQL installation...${NC}"
    if ! kubectl get statefulset postgresql -n egov-db >/dev/null 2>&1; then
        echo -e "${RED}PostgreSQL statefulset not found${NC}"
        return 1
    fi
    
    if ! kubectl wait --for=condition=Ready pods -l app=postgresql -n egov-db --timeout=300s; then
        echo -e "${RED}PostgreSQL pod is not ready${NC}"
        return 1
    fi
    
    echo -e "${GREEN}PostgreSQL installation verified successfully${NC}"
    return 0
}

# Redis 설치 확인 함수 추가
check_redis() {
    echo -e "${YELLOW}Verifying Redis installation...${NC}"
    if ! kubectl get statefulset redis -n egov-db >/dev/null 2>&1; then
        echo -e "${RED}Redis statefulset not found${NC}"
        return 1
    fi
    
    if ! kubectl wait --for=condition=Ready pods -l app=redis -n egov-db --timeout=300s; then
        echo -e "${RED}Redis pod is not ready${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Redis installation verified successfully${NC}"
    return 0
}

# 메인 설치 프로세스
echo -e "${YELLOW}Starting setup process...${NC}"

# 1. Istio 설치
echo -e "\n${YELLOW}[1/7] Installing Istio...${NC}"
${SCRIPT_DIR}/01-setup-istio.sh
check_error "Istio installation"
check_istio

# 2. Namespace 설정
echo -e "\n${YELLOW}[2/7] Setting up Namespaces...${NC}"
${SCRIPT_DIR}/02-setup-namespaces.sh
check_error "Namespace setup"
check_namespaces

# 3. Monitoring 설정
echo -e "\n${YELLOW}[3/7] Setting up Monitoring...${NC}"
${SCRIPT_DIR}/03-setup-monitoring.sh
check_error "Monitoring setup"
check_monitoring

# 4. MySQL 설정
echo -e "\n${YELLOW}[4/7] Setting up Databases...${NC}"
${SCRIPT_DIR}/04-setup-db.sh
check_error "Database setup"
check_mysql
check_opensearch
check_postgresql
check_redis

# 5. CICD 설정
echo -e "\n${YELLOW}[5/7] Setting up CICD...${NC}"
${SCRIPT_DIR}/05-setup-cicd.sh
check_error "CICD setup"

# 6. Infrastructure 설정
echo -e "\n${YELLOW}[6/7] Setting up Infrastructure...${NC}"
${SCRIPT_DIR}/06-setup-infrastructure.sh
check_error "Infrastructure setup"
check_infrastructure

# 7. Applications 설정
echo -e "\n${YELLOW}[7/7] Setting up Applications...${NC}"
${SCRIPT_DIR}/07-setup-applications.sh
check_error "Applications setup"
check_applications

# 최종 상태 출력
echo -e "\n${YELLOW}Final Status:${NC}"
kubectl get pods --all-namespaces

echo -e "\n${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}Please check the services using:${NC}"
${SCRIPT_DIR}/09-show-access-info.sh

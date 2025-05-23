#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 스크립트 디렉토리 경로 설정
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 에러 체크 함수
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error during $1${NC}"
        exit 1
    fi
}

# 함수: 애플리케이션 정리 확인
verify_applications_cleanup() {
    echo -e "${YELLOW}Verifying applications cleanup...${NC}"
    local apps=("egov-main" "egov-board" "egov-login" "egov-author" "egov-mobileid" "egov-questionnaire" "egov-cmmncode" "egov-search")
    
    for app in "${apps[@]}"; do
        if kubectl get deployment ${app} -n egov-app >/dev/null 2>&1; then
            echo -e "${RED}Application ${app} still exists${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}Applications cleanup verified successfully${NC}"
    return 0
}

# 함수: 인프라 정리 확인
verify_infrastructure_cleanup() {
    echo -e "${YELLOW}Verifying infrastructure cleanup...${NC}"
    local services=("gateway-server" "rabbitmq")
    
    for svc in "${services[@]}"; do
        if kubectl get deployment ${svc} -n egov-infra >/dev/null 2>&1; then
            echo -e "${RED}Infrastructure service ${svc} still exists${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}Infrastructure cleanup verified successfully${NC}"
    return 0
}

# 함수: Database 정리 확인
verify_db_cleanup() {
    echo -e "${YELLOW}Verifying Database cleanup...${NC}"
    if kubectl get statefulset -n egov-db >/dev/null 2>&1 || kubectl get pvc -n egov-db >/dev/null 2>&1; then
        echo -e "${RED}Database statefulset or PVC still exists${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Database cleanup verified successfully${NC}"
    return 0
}

# 함수: 모니터링 정리 확인
verify_monitoring_cleanup() {
    echo -e "${YELLOW}Verifying monitoring cleanup...${NC}"
    local services=("prometheus" "grafana" "kiali" "jaeger")
    
    for svc in "${services[@]}"; do
        if kubectl get deployment ${svc} -n egov-monitoring >/dev/null 2>&1; then
            echo -e "${RED}Monitoring service ${svc} still exists${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}Monitoring cleanup verified successfully${NC}"
    return 0
}

# 함수: 네임스페이스 정리 확인
verify_namespaces_cleanup() {
    echo -e "${YELLOW}Verifying namespaces cleanup...${NC}"
    local namespaces=("egov-infra" "egov-app" "egov-db" "egov-monitoring")
    
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace ${ns} >/dev/null 2>&1; then
            echo -e "${RED}Namespace ${ns} still exists${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}Namespaces cleanup verified successfully${NC}"
    return 0
}

# 함수: Istio 정리 확인
verify_istio_cleanup() {
    echo -e "${YELLOW}Verifying Istio cleanup...${NC}"
    
    # Istio 네임스페이스 확인
    if kubectl get namespace istio-system >/dev/null 2>&1; then
        echo -e "${RED}Istio namespace still exists${NC}"
        return 1
    fi
    
    # Istio injection 레이블 확인
    if kubectl get namespace egov-app -o yaml | grep -q "istio-injection"; then
        echo -e "${RED}Istio injection label still exists on egov-app namespace${NC}"
        return 1
    fi
    
    # Istio 매니페스트 확인
    if kubectl get telemetry -n egov-app egov-apps-telemetry >/dev/null 2>&1; then
        echo -e "${RED}Istio telemetry configuration still exists${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Istio cleanup verified successfully${NC}"
    return 0
}

# 함수: CICD 정리 확인
verify_cicd_cleanup() {
    echo -e "${YELLOW}Verifying CICD cleanup...${NC}"
    local services=("jenkins" "gitlab" "sonarqube" "nexus")
    
    for svc in "${services[@]}"; do
        if kubectl get deployment ${svc} -n egov-cicd >/dev/null 2>&1 || \
           kubectl get statefulset ${svc} -n egov-cicd >/dev/null 2>&1; then
            echo -e "${RED}CICD service ${svc} still exists${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}CICD cleanup verified successfully${NC}"
    return 0
}

# 메인 정리 프로세스
echo -e "${YELLOW}Starting cleanup process...${NC}"

# 1. Applications 정리
echo -e "\n${YELLOW}[1/7] Cleaning up Applications...${NC}"
${SCRIPT_DIR}/01-cleanup-applications.sh
check_error "Applications cleanup"
verify_applications_cleanup

# 2. Infrastructure 정리
echo -e "\n${YELLOW}[2/7] Cleaning up Infrastructure...${NC}"
${SCRIPT_DIR}/02-cleanup-infrastructure.sh
check_error "Infrastructure cleanup"
verify_infrastructure_cleanup

# 3. Database 정리
echo -e "\n${YELLOW}[3/7] Cleaning up Database...${NC}"
${SCRIPT_DIR}/03-cleanup-db.sh
check_error "Database cleanup"
verify_db_cleanup

# 4. CICD 정리
echo -e "\n${YELLOW}[4/7] Cleaning up CICD...${NC}"
${SCRIPT_DIR}/04-cleanup-cicd.sh
check_error "CICD cleanup"
verify_cicd_cleanup

# 5. Monitoring 정리
echo -e "\n${YELLOW}[5/7] Cleaning up Monitoring...${NC}"
${SCRIPT_DIR}/05-cleanup-monitoring.sh
check_error "Monitoring cleanup"
verify_monitoring_cleanup

# 6. Namespaces 정리
echo -e "\n${YELLOW}[6/7] Cleaning up Namespaces...${NC}"
${SCRIPT_DIR}/06-cleanup-namespaces.sh
check_error "Namespaces cleanup"
verify_namespaces_cleanup

# 7. Istio 정리
echo -e "\n${YELLOW}[7/7] Cleaning up Istio...${NC}"
${SCRIPT_DIR}/07-cleanup-istio.sh
check_error "Istio cleanup"
verify_istio_cleanup

# 최종 상태 확인
echo -e "\n${YELLOW}Final Status Check:${NC}"
echo -e "${YELLOW}Remaining Namespaces:${NC}"
kubectl get namespaces

echo -e "\n${GREEN}Cleanup completed successfully!${NC}"

#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 사용법 함수
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 [namespace]"
    echo -e "\n${GREEN}Available namespaces:${NC}"
    echo "  - egov-app"
    echo "  - egov-db"
    echo "  - egov-infra"
    echo "  - egov-monitoring"
    echo "  - all (checks all namespaces)"
    exit 1
}

# 인자 체크
if [ $# -eq 0 ]; then
    usage
fi

NAMESPACE=$1

# Pod 상태 체크 함수
check_pods() {
    local ns=$1
    local has_issues=0
    
    echo -e "\n${BLUE}Checking pods in namespace: ${ns}${NC}"
    echo "----------------------------------------"
    
    # Pod 목록 가져오기
    local pods=$(kubectl get pods -n ${ns} -o json)
    
    # 각 Pod 상태 확인
    echo "${pods}" | jq -r '.items[] | "\(.metadata.name) \(.status.phase) \(.status.containerStatuses[]?.ready)"' | while read -r pod phase ready; do
        local status_color=$GREEN
        local status_msg="OK"
        local details=""
        
        # Pod 상태 확인
        if [ "$phase" != "Running" ]; then
            status_color=$RED
            status_msg="Error"
            details="(Phase: ${phase})"
            has_issues=1
        elif [ "$ready" != "true" ]; then
            status_color=$YELLOW
            status_msg="Warning"
            details="(Not Ready)"
            has_issues=1
        fi
        
        # 재시작 횟수 확인
        local restarts=$(kubectl get pod ${pod} -n ${ns} -o jsonpath='{.status.containerStatuses[0].restartCount}')
        if [ "${restarts}" -gt 0 ]; then
            details="${details} (Restarts: ${restarts})"
            if [ "${status_color}" == "${GREEN}" ]; then
                status_color=$YELLOW
                status_msg="Warning"
            fi
            has_issues=1
        fi
        
        # 상태 출력
        echo -e "${status_color}[$status_msg]${NC} Pod: ${pod} ${details}"
        
        # 문제가 있는 경우 추가 정보 출력
        if [ "${status_color}" != "${GREEN}" ]; then
            echo "  - Events:"
            kubectl get events -n ${ns} --field-selector involvedObject.name=${pod} --sort-by='.lastTimestamp' | tail -n 3
            echo "  - Pod Description:"
            kubectl describe pod ${pod} -n ${ns} | grep -A 3 "State:"
            echo
        fi
    done
    
    # 리소스 사용량 확인
    echo -e "\n${BLUE}Resource Usage:${NC}"
    kubectl top pod -n ${ns} 2>/dev/null || echo "Resource metrics not available"
    
    # 모니터링 네임스페이스인 경우 서비스 엔드포인트 정보 출력
    if [ "${ns}" == "egov-monitoring" ]; then
        echo -e "\n${BLUE}Monitoring Service Endpoints:${NC}"
        echo "Kiali:      http://localhost:30001"
        echo "Grafana:    http://localhost:30002"
        echo "Jaeger:     http://localhost:30003"
        echo "Prometheus: http://localhost:30004"
    fi
    
    return ${has_issues}
}

# 전체 네임스페이스 체크
check_all_namespaces() {
    local total_issues=0
    
    for ns in "egov-app" "egov-db" "egov-infra" "egov-monitoring"; do
        check_pods ${ns}
        if [ $? -ne 0 ]; then
            total_issues=1
        fi
    done
    
    return ${total_issues}
}

# 메인 로직
case ${NAMESPACE} in
    "all")
        echo -e "${BLUE}Checking all namespaces...${NC}"
        check_all_namespaces
        ;;
    "egov-app"|"egov-db"|"egov-infra"|"egov-monitoring")
        check_pods ${NAMESPACE}
        ;;
    *)
        echo -e "${RED}Error: Invalid namespace '${NAMESPACE}'${NC}"
        usage
        ;;
esac

# 최종 상태 출력
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}All pods are healthy!${NC}"
    exit 0
else
    echo -e "\n${RED}Some pods have issues. Please check the details above.${NC}"
    exit 1
fi

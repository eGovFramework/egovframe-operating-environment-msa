#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 사용법 함수
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 <application-name> [-f|--follow] [-t|--tail <lines>] [-p|--previous]"
    echo -e "\n${GREEN}Available applications:${NC}"
    echo "Application Services (egov-app namespace):"
    echo "  - egov-main"
    echo "  - egov-board"
    echo "  - egov-login"
    echo "  - egov-author"
    echo "  - egov-mobileid"
    echo "  - egov-questionnaire"
    echo "  - egov-cmmncode"
    echo "  - egov-search"
    echo "  - egov-hello"
    
    echo -e "\nDatabase Services (egov-db namespace):"
    echo "  - mysql"
    echo "  - opensearch"

    echo -e "\nInfrastructure Services (egov-infra namespace):"
    echo "  - gateway-server"
    echo "  - rabbitmq"
    
    echo -e "\nMonitoring Services (egov-monitoring namespace):"
    echo "  - prometheus"
    echo "  - grafana"
    echo "  - kiali"
    echo "  - jaeger"
    echo "  - loki"
    echo "  - otel-collector"

    echo -e "\n${GREEN}Options:${NC}"
    echo "  -f, --follow     Follow log output"
    echo "  -t, --tail      Number of lines to show (default: 100)"
    echo "  -p, --previous  Show logs from previous container instance"
    exit 1
}

# 기본값 설정
FOLLOW=""
TAIL="100"
PREVIOUS=""
APP_NAME=""

# 인자 체크
if [ $# -eq 0 ]; then
    usage
fi

# 유효한 애플리케이션 목록
EGOV_APP_SERVICES=("egov-main" "egov-board" "egov-login" "egov-author" "egov-mobileid" "egov-questionnaire" "egov-cmmncode" "egov-search" "egov-hello")
EGOV_DB_SERVICES=("mysql" "opensearch")
MONITORING_SERVICES=("prometheus" "grafana" "kiali" "jaeger" "loki" "otel-collector")
EGOV_INFRA_SERVICES=("gateway-server" "rabbitmq")

# 인자 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW="--follow"
            shift
            ;;
        -t|--tail)
            TAIL="$2"
            shift 2
            ;;
        -p|--previous)
            PREVIOUS="--previous"
            shift
            ;;
        *)
            if [ -z "$APP_NAME" ]; then
                APP_NAME="$1"
            else
                echo -e "${RED}Error: Unknown parameter $1${NC}"
                usage
            fi
            shift
            ;;
    esac
done

# 네임스페이스와 라벨 결정
if [[ " ${EGOV_APP_SERVICES[@]} " =~ " ${APP_NAME} " ]]; then
    NAMESPACE="egov-app"
    LABEL="app=${APP_NAME}"
elif [[ " ${EGOV_DB_SERVICES[@]} " =~ " ${APP_NAME} " ]]; then
    NAMESPACE="egov-db"
    LABEL="app=${APP_NAME}"
elif [[ " ${MONITORING_SERVICES[@]} " =~ " ${APP_NAME} " ]]; then
    NAMESPACE="egov-monitoring"
    if [ "${APP_NAME}" == "otel-collector" ]; then
        LABEL="app.kubernetes.io/name=otel-collector-collector"
    else
        LABEL="app=${APP_NAME}"
    fi
elif [[ " ${EGOV_INFRA_SERVICES[@]} " =~ " ${APP_NAME} " ]]; then
    NAMESPACE="egov-infra"
    LABEL="app=${APP_NAME}"
else
    echo -e "${RED}Error: Invalid application name '${APP_NAME}'${NC}"
    usage
fi

# Pod 존재 여부 확인
if [ "${APP_NAME}" == "mysql" ]; then
    POD_NAME=$(kubectl get pods -n ${NAMESPACE} -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
elif [ "${APP_NAME}" == "opensearch" ]; then
    POD_NAME=$(kubectl get pods -n ${NAMESPACE} -l app=opensearch -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
elif [[ " ${MONITORING_SERVICES[@]} " =~ " ${APP_NAME} " ]]; then
    POD_NAME=$(kubectl get pods -n ${NAMESPACE} | grep "^${APP_NAME}-" | awk '{print $1}' | head -n 1)
else
    POD_NAME=$(kubectl get pods -n ${NAMESPACE} -l ${LABEL} -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
fi

if [ -z "$POD_NAME" ]; then
    echo -e "${RED}Error: No pods found for ${APP_NAME} in namespace ${NAMESPACE}${NC}"
    echo -e "\n${YELLOW}Available pods in ${NAMESPACE}:${NC}"
    kubectl get pods -n ${NAMESPACE}
    exit 1
fi

# kubectl 명령어 구성
KUBECTL_CMD="kubectl logs -n ${NAMESPACE} ${POD_NAME} ${FOLLOW} --tail=${TAIL} ${PREVIOUS}"

# 로그 헤더 출력
echo -e "${GREEN}Showing logs for ${APP_NAME}${NC}"
echo -e "${YELLOW}Namespace: ${NAMESPACE}${NC}"
echo -e "${YELLOW}Pod: ${POD_NAME}${NC}"
echo "----------------------------------------"

# 로그 출력
eval ${KUBECTL_CMD}

# follow 옵션이 없을 때만 명령어 출력
if [ -z "$FOLLOW" ]; then
    echo -e "\n----------------------------------------"
    echo -e "${BLUE}Command used:${NC}"
    echo -e "${GREEN}${KUBECTL_CMD}${NC}"
fi

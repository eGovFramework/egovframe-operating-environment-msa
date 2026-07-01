
#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 스크립트 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 함수: 오류 체크
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error occurred in $1${NC}"
        exit 1
    fi
}

# 함수: 리소스 대기
wait_for_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    local timeout=$4

    echo -e "${YELLOW}Waiting for ${resource_type} ${resource_name} to be ready...${NC}"
    
    case ${resource_type} in
        "statefulset")
            kubectl wait --for=jsonpath='{.status.availableReplicas}'=1 ${resource_type}/${resource_name} -n ${namespace} --timeout=${timeout}s
            ;;
        "deployment"|"pod")
            kubectl wait --for=condition=Ready pods -l app=${resource_name} -n ${namespace} --timeout=${timeout}s
            ;;
        *)
            echo -e "${RED}Unknown resource type: ${resource_type}${NC}"
            return 1
            ;;
    esac
    
    check_error "waiting for ${resource_type} ${resource_name}"
}

# CICD 네임스페이스 생성
echo -e "\n${YELLOW}Creating egov-cicd namespace...${NC}"
kubectl create namespace egov-cicd 2>/dev/null || true

# 로컬 PVC 생성 (local-path StorageClass)
echo -e "\n${YELLOW}Creating local PVCs for CI/CD...${NC}"
kubectl apply -f ${BASE_DIR}/manifests/egov-cicd/jenkins-pv-local-path.yaml
kubectl apply -f ${BASE_DIR}/manifests/egov-cicd/nexus-pv-local-path.yaml
kubectl apply -f ${BASE_DIR}/manifests/egov-cicd/sonarqube-pv-local-path.yaml
check_error "CI/CD PVC creation"

# Jenkins StatefulSet 배포
echo -e "\n${YELLOW}Deploying Jenkins StatefulSet...${NC}"
kubectl apply -f ${BASE_DIR}/manifests/egov-cicd/jenkins-statefulset.yaml
check_error "Jenkins statefulset deployment"

# GitLab 설치 (선택: gitlab-statefulset.yaml hostPath를 로컬 경로로 수정 후 사용)
if [ "${INSTALL_GITLAB:-false}" = "true" ]; then
    echo -e "\n${YELLOW}Installing GitLab...${NC}"
    kubectl apply -f ${BASE_DIR}/manifests/egov-cicd/gitlab-statefulset.yaml
    check_error "GitLab installation"
else
    echo -e "\n${YELLOW}Skipping GitLab (privileged). Set INSTALL_GITLAB=true to install.${NC}"
fi

# SonarQube 설치
echo -e "\n${YELLOW}Installing SonarQube...${NC}"
kubectl apply -f ${BASE_DIR}/manifests/egov-cicd/sonarqube-deployment.yaml
check_error "SonarQube installation"

# Nexus 설치
echo -e "\n${YELLOW}Installing Nexus...${NC}"
kubectl apply -f ${BASE_DIR}/manifests/egov-cicd/nexus-statefulset.yaml
check_error "Nexus installation"

# 리소스 준비 대기
echo -e "\n${YELLOW}Waiting for CICD resources to be ready...${NC}"
wait_for_resource statefulset jenkins egov-cicd 300
if [ "${INSTALL_GITLAB:-false}" = "true" ]; then
    wait_for_resource statefulset gitlab egov-cicd 300
fi
wait_for_resource deployment sonarqube egov-cicd 300
wait_for_resource statefulset nexus egov-cicd 300

# Jenkins 초기 비밀번호 출력
echo -e "\n${YELLOW}Jenkins initial admin password:${NC}"
kubectl exec -n egov-cicd jenkins-0 -- cat /var/jenkins_home/secrets/initialAdminPassword

# 설치 완료 메시지 및 접근 정보
echo -e "\n${GREEN}CICD setup completed successfully!${NC}"
echo -e "\n${BLUE}Access Information (port-forward required):${NC}"
echo -e "Run: ${BASE_DIR}/scripts/utils/cicd-port-forward.sh start"
echo -e ""
echo -e "Jenkins:   http://localhost:30011"
if [ "${INSTALL_GITLAB:-false}" = "true" ]; then
    echo -e "GitLab:    http://localhost:30012"
fi
echo -e "SonarQube: http://localhost:30013"
echo -e "Nexus:     http://localhost:30014"

echo -e "\n${YELLOW}Please check the status of all pods:${NC}"
kubectl get pods -n egov-cicd

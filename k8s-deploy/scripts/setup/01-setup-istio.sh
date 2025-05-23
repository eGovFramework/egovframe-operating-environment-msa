#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ISTIO_DIR="${BASE_DIR}/bin/istio-1.25.0"
ISTIO_VERSION="1.25.0"
TARGET_ARCH="arm64"

# Istio가 이미 설치되어 있는지 확인
if [ -d "${ISTIO_DIR}" ]; then
    echo -e "${YELLOW}Istio ${ISTIO_VERSION} is already downloaded in ${ISTIO_DIR}${NC}"
else
    echo -e "${GREEN}Downloading Istio ${ISTIO_VERSION}...${NC}"
    
    # 현재 디렉토리 저장
    CURRENT_DIR=$(pwd)
    
    # bin 디렉토리 생성 및 이동
    mkdir -p "${BASE_DIR}/bin"
    cd "${BASE_DIR}/bin"
    
    # Istio 다운로드
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=${TARGET_ARCH} sh -
    
    # 원래 디렉토리로 복귀
    cd "${CURRENT_DIR}"
fi

# Istio 바이너리를 시스템 경로에 추가
echo -e "${GREEN}Adding Istio binary to PATH...${NC}"
export PATH="${ISTIO_DIR}/bin:$PATH"

# Istio 설치
echo -e "${GREEN}Installing Istio with default profile...${NC}"
istioctl install --set profile=default -y

# istio-system 네임스페이스의 상태 확인
echo -e "${YELLOW}Checking istio-system namespace status...${NC}"
kubectl get pods -n istio-system

# Istio 설정 적용
echo -e "${GREEN}Applying Istio configuration...${NC}"
kubectl apply -f "${BASE_DIR}/manifests/egov-istio/config.yaml"

# egov-app 네임스페이스가 없다면 생성
echo -e "${YELLOW}Creating egov-app namespace ${NC}"
kubectl create namespace egov-app --dry-run=client -o yaml | kubectl apply -f -

# Istio injection 레이블 추가
echo -e "${YELLOW}Enabling Istio injection for egov-app namespace...${NC}"
kubectl label namespace egov-app istio-injection=enabled --overwrite

# Telemetry 설정 적용
echo -e "${GREEN}Applying Istio telemetry configuration...${NC}"
kubectl apply -f "${BASE_DIR}/manifests/egov-istio/telemetry.yaml"

echo -e "${YELLOW}Waiting for all pods to be ready...${NC}"
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s

# Telemetry 설정 확인
echo -e "${YELLOW}Verifying telemetry configuration...${NC}"
if kubectl get telemetry -n egov-app egov-apps-telemetry >/dev/null 2>&1; then
    echo -e "${GREEN}Telemetry configuration verified successfully${NC}"
else
    echo -e "${RED}Failed to verify telemetry configuration${NC}"
    exit 1
fi

echo -e "${GREEN}Istio installation completed!${NC}"

# PATH 설정을 영구적으로 적용하기 위한 안내
echo -e "\n${YELLOW}To permanently add Istio to your PATH, add the following line to your ~/.bashrc or ~/.zshrc:${NC}"
echo -e "${GREEN}export PATH=\"${ISTIO_DIR}/bin:\$PATH\"${NC}"

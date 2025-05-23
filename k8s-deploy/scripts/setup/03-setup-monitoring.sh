#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# egov-monitoring 네임스페이스 확인 및 생성
if ! kubectl get namespace egov-monitoring >/dev/null 2>&1; then
    echo -e "${YELLOW}Creating egov-monitoring namespace...${NC}"
    kubectl create namespace egov-monitoring
fi

# cert-manager 설치 전 기존 설치 제거
echo -e "${YELLOW}Cleaning up existing cert-manager installation...${NC}"
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml --ignore-not-found
sleep 30

# cert-manager webhook configuration 임시 비활성화
echo -e "${YELLOW}Temporarily disabling cert-manager webhook...${NC}"
kubectl delete validatingwebhookconfiguration cert-manager-webhook --ignore-not-found
kubectl delete mutatingwebhookconfiguration cert-manager-webhook --ignore-not-found
sleep 10

# cert-manager 설치
echo -e "${YELLOW}Installing cert-manager...${NC}"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# cert-manager가 준비될 때까지 충분히 대기
echo -e "${YELLOW}Waiting for cert-manager pods to be ready...${NC}"
kubectl wait --for=condition=Ready pods -l app=cert-manager -n cert-manager --timeout=300s
kubectl wait --for=condition=Ready pods -l app=cainjector -n cert-manager --timeout=300s
kubectl wait --for=condition=Ready pods -l app=webhook -n cert-manager --timeout=300s

echo -e "${YELLOW}Waiting for cert-manager webhook to be fully ready...${NC}"
sleep 90

# OpenTelemetry Operator 설치 전 기존 설치 제거
echo -e "${YELLOW}Cleaning up existing OpenTelemetry Operator...${NC}"
kubectl delete -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml --ignore-not-found
sleep 30

# OpenTelemetry Operator 설치
echo -e "${YELLOW}Installing OpenTelemetry Operator...${NC}"
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml

# OpenTelemetry Operator가 준비될 때까지 대기
echo -e "${YELLOW}Waiting for OpenTelemetry Operator to be ready...${NC}"
kubectl wait --for=condition=Ready pods -l control-plane=controller-manager -n opentelemetry-operator-system --timeout=300s

# CRD 설치 확인
echo -e "${YELLOW}Verifying OpenTelemetry CRDs...${NC}"
if ! kubectl get crd opentelemetrycollectors.opentelemetry.io >/dev/null 2>&1; then
    echo -e "${RED}OpenTelemetry CRDs not found. Installation may have failed.${NC}"
    exit 1
fi

# AlertManager 설정 적용
echo -e "${YELLOW}Setting up AlertManager configuration...${NC}"
kubectl apply -f "../../manifests/egov-monitoring/alertmanager-config.yaml"
kubectl apply -f "../../manifests/egov-monitoring/circuit-breaker-alerts-configmap.yaml"

# PV 생성
echo -e "${YELLOW}Creating Prometheus PV...${NC}"
kubectl apply -f "../../manifests/egov-monitoring/prometheus-pv.yaml"

# PVC 바인딩 상태 확인
echo -e "${YELLOW}Waiting for Prometheus PVC to be bound...${NC}"
while [[ $(kubectl get pvc prometheus-pvc-nfs -n egov-monitoring -o jsonpath='{.status.phase}') != "Bound" ]]; do
    echo -e "${YELLOW}Waiting for PVC to be bound...${NC}"
    sleep 5
done

# 모니터링 컴포넌트 설치
echo -e "${YELLOW}Installing monitoring components...${NC}"
for addon in prometheus grafana kiali jaeger loki alertmanager; do
    echo -e "${GREEN}Installing ${addon}...${NC}"
    kubectl apply -f "../../manifests/egov-monitoring/${addon}.yaml"
    sleep 5
done

# OpenTelemetry Collector 설정 적용
echo -e "${YELLOW}Applying OpenTelemetry Collector configuration...${NC}"
kubectl apply -f "../../manifests/egov-monitoring/opentelemetry-collector.yaml"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to apply OpenTelemetry Collector configuration${NC}"
    exit 1
fi

# Collector Pod 준비 대기
echo -e "${YELLOW}Waiting for OpenTelemetry Collector to be ready...${NC}"
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=otel-collector-collector -n egov-monitoring --timeout=300s

# Pod 상태 확인
echo -e "${YELLOW}Checking OpenTelemetry Collector pod status...${NC}"
kubectl get pods -n egov-monitoring -l app.kubernetes.io/name=otel-collector-collector -o wide

# AlertManager 준비 대기
echo -e "${YELLOW}Waiting for AlertManager to be ready...${NC}"
kubectl wait --for=condition=Ready pods -l app=alertmanager -n egov-monitoring --timeout=300s

# 설치 완료까지 대기
echo -e "${YELLOW}Waiting for all pods to be ready...${NC}"
kubectl wait --for=condition=Ready pods --all -n egov-monitoring --timeout=300s

# 설치된 pods 확인
echo -e "${GREEN}Checking installed pods:${NC}"
kubectl get pods -n egov-monitoring

# 서비스 확인
echo -e "${GREEN}Checking services:${NC}"
kubectl get svc -n egov-monitoring

echo -e "${GREEN}Telemetry configuration completed!${NC}"

# 접근 URL 출력
echo -e "${YELLOW}Access URLs:${NC}"
echo "Kiali:        http://localhost:30001"
echo "Grafana:      http://localhost:30002"
echo "Jaeger:       http://localhost:30003"
echo "Prometheus:   http://localhost:30004"
echo "AlertManager: http://localhost:9093 (requires port-forward)"
echo -e "\n${YELLOW}To access AlertManager, run:${NC}"
echo "kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093"


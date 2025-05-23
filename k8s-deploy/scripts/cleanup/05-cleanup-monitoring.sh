#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

NAMESPACE="egov-monitoring"

echo -e "${YELLOW}Removing all addons from ${NAMESPACE} namespace...${NC}"

# 1. AlertManager 관련 리소스 제거
echo -e "${YELLOW}Removing AlertManager resources...${NC}"
kubectl delete -f ../../manifests/egov-monitoring/alertmanager.yaml 2>/dev/null || true
kubectl delete secret alertmanager-config -n ${NAMESPACE} 2>/dev/null || true
kubectl delete configmap prometheus-rules -n ${NAMESPACE} 2>/dev/null || true
kubectl delete -f ../../manifests/egov-monitoring/alertmanager-config.yaml 2>/dev/null || true
kubectl delete -f ../../manifests/egov-monitoring/circuit-breaker-alerts-configmap.yaml 2>/dev/null || true

# 2. YAML 파일을 통해 설치된 다른 리소스들 제거
echo -e "${YELLOW}Removing monitoring addons...${NC}"
kubectl delete -f ../../manifests/egov-monitoring/kiali.yaml 2>/dev/null
kubectl delete -f ../../manifests/egov-monitoring/prometheus.yaml 2>/dev/null
kubectl delete -f ../../manifests/egov-monitoring/grafana.yaml 2>/dev/null
kubectl delete -f ../../manifests/egov-monitoring/jaeger.yaml 2>/dev/null
kubectl delete -f ../../manifests/egov-monitoring/opentelemetry-collector.yaml 2>/dev/null

# Prometheus PV/PVC 제거
kubectl delete -f ../../manifests/egov-monitoring/prometheus-pv.yaml 2>/dev/null

# OpenTelemetry Operator 제거
echo -e "${YELLOW}Removing OpenTelemetry Operator...${NC}"
kubectl delete -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml 2>/dev/null

# cert-manager 제거
echo -e "${YELLOW}Removing cert-manager...${NC}"
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# 3. 추가적인 리소스 정리
echo -e "${YELLOW}Cleaning up remaining resources...${NC}"
kubectl delete service jaeger-collector tracing zipkin -n ${NAMESPACE} 2>/dev/null

# 4. 삭제 완료 대기
echo -e "${YELLOW}Waiting for resources to be terminated...${NC}"
kubectl wait --for=delete pods --all -n ${NAMESPACE} --timeout=60s 2>/dev/null

# 5. 확인
echo -e "${GREEN}Checking remaining resources in ${NAMESPACE}:${NC}"
kubectl get all -n ${NAMESPACE}

echo -e "${GREEN}Addon cleanup completed!${NC}"

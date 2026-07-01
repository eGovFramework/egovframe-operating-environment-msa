#!/bin/bash

# CI/CD 서비스 port-forward 헬퍼 (ClusterIP 전환 후 로컬 접근용)
# 사용법: ./cicd-port-forward.sh [start|stop|status]

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

NAMESPACE="egov-cicd"
PID_DIR="${TMPDIR:-/tmp}/egov-cicd-port-forward"

SERVICES=(
  "jenkins:30011:8080"
  "gitlab:30012:80"
  "sonarqube:30013:9000"
  "nexus:30014:8081"
)

check_namespace() {
  if ! kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
    echo -e "${RED}Namespace ${NAMESPACE} not found. Run 05-setup-cicd.sh first.${NC}"
    exit 1
  fi
}

start_forward() {
  check_namespace
  mkdir -p "${PID_DIR}"

  echo -e "${YELLOW}Starting CI/CD port-forwards...${NC}"
  for entry in "${SERVICES[@]}"; do
    IFS=':' read -r svc local_port remote_port <<< "${entry}"
    pid_file="${PID_DIR}/${svc}.pid"

    if [ -f "${pid_file}" ] && kill -0 "$(cat "${pid_file}")" 2>/dev/null; then
      echo -e "${GREEN}${svc}: already running (localhost:${local_port})${NC}"
      continue
    fi

    kubectl port-forward "svc/${svc}" -n "${NAMESPACE}" "${local_port}:${remote_port}" \
      >/dev/null 2>&1 &
    echo $! > "${pid_file}"
    echo -e "${GREEN}${svc}: http://localhost:${local_port}${NC}"
  done

  echo -e "\n${YELLOW}GitLab SSH (optional):${NC}"
  echo "kubectl port-forward svc/gitlab -n ${NAMESPACE} 30022:22"
}

stop_forward() {
  if [ ! -d "${PID_DIR}" ]; then
    echo -e "${YELLOW}No port-forward processes found.${NC}"
    return
  fi

  echo -e "${YELLOW}Stopping CI/CD port-forwards...${NC}"
  for pid_file in "${PID_DIR}"/*.pid; do
    [ -f "${pid_file}" ] || continue
    pid=$(cat "${pid_file}")
    if kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" 2>/dev/null || true
    fi
    rm -f "${pid_file}"
  done
  echo -e "${GREEN}Stopped.${NC}"
}

show_status() {
  if [ ! -d "${PID_DIR}" ]; then
    echo -e "${YELLOW}No port-forward processes running.${NC}"
    return
  fi

  for entry in "${SERVICES[@]}"; do
    IFS=':' read -r svc local_port _ <<< "${entry}"
    pid_file="${PID_DIR}/${svc}.pid"
    if [ -f "${pid_file}" ] && kill -0 "$(cat "${pid_file}")" 2>/dev/null; then
      echo -e "${GREEN}${svc}: running → http://localhost:${local_port}${NC}"
    else
      echo -e "${RED}${svc}: stopped${NC}"
    fi
  done
}

case "${1:-start}" in
  start) start_forward ;;
  stop) stop_forward ;;
  status) show_status ;;
  *)
    echo "Usage: $0 [start|stop|status]"
    exit 1
    ;;
esac

#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 디렉토리 확인
LOG_DIR="logs"
if [ ! -d "$LOG_DIR" ]; then
    echo -e "${YELLOW}Warning: Log directory not found${NC}"
fi

# 코어 서비스 정의
core_services=(
    "ConfigServer"
    "EurekaServer"
    "GatewayServer"
)

# 일반 서비스 정의
services=(
    "EgovAuthor"
    "EgovBoard"
    "EgovCmmnCode"
    "EgovLogin"
    "EgovMain"
    "EgovMobileId"
    "EgovQuestionnaire"
    "EgovSearch"
)

# 서비스 상태 확인 함수
check_service() {
    local service=$1
    local pid=$(pgrep -f "$service.jar")
    
    if [ ! -z "$pid" ]; then
        echo -e "${GREEN}✓ $service is running (PID: $pid)${NC}"
        
        # PID 기반 로그 파일 확인
        local log_file="logs/${service}_${pid}.log"
        if [ -f "$log_file" ]; then
            local errors=$(tail -n 50 "$log_file" | grep -i "error" | wc -l)
            if [ $errors -gt 0 ]; then
                echo -e "${YELLOW}  ⚠ Found $errors recent errors in log${NC}"
            fi
        fi
        
        return 0
    else
        echo -e "${RED}✗ $service is not running${NC}"
        return 1
    fi
}

# 헤더 출력
echo "=== Service Status Check ==="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# 코어 서비스 상태 확인
echo "Core Services:"
echo "-------------"
core_status=0
for service in "${core_services[@]}"; do
    check_service "$service"
    if [ $? -ne 0 ]; then
        core_status=1
    fi
done
echo

# 일반 서비스 상태 확인
echo "Application Services:"
echo "-------------------"
app_status=0
for service in "${services[@]}"; do
    check_service "$service"
    if [ $? -ne 0 ]; then
        app_status=1
    fi
done
echo

# 전체 상태 요약
echo "=== Status Summary ==="
if [ $core_status -eq 0 ]; then
    echo -e "${GREEN}Core Services: All Running${NC}"
else
    echo -e "${RED}Core Services: Some Failed${NC}"
fi

if [ $app_status -eq 0 ]; then
    echo -e "${GREEN}Application Services: All Running${NC}"
else
    echo -e "${RED}Application Services: Some Failed${NC}"
fi

# 종료 코드 설정
if [ $core_status -eq 0 ] && [ $app_status -eq 0 ]; then
    exit 0
else
    exit 1
fi

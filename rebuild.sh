#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 실행 시작 시간 기록
start_time=$(date +%s)

# 함수: 경과 시간 계산
show_elapsed_time() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))
    echo -e "${YELLOW}Total elapsed time: ${minutes}m ${seconds}s${NC}"
}

# 함수: 작업 상태 출력
print_status() {
    local step=$1
    local status=$2
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✓ $step completed successfully${NC}"
    else
        echo -e "${RED}✗ $step failed${NC}"
        show_elapsed_time
        exit 1
    fi
}

# 서비스 배열 정의
services=(
    "ConfigServer"
    "EgovAuthor"
    "EgovBoard"
    "EgovCmmnCode"
    "EgovLogin"
    "EgovMain"
    "EgovMobileId"
    "EgovQuestionnaire"
    "EgovSearch"
    "EurekaServer"
    "GatewayServer"
)

# 인자가 있는 경우 서비스 이름 유효성 검사
if [ $# -eq 1 ]; then
    valid_service=false
    for service in "${services[@]}"; do
        if [ "$1" == "$service" ]; then
            valid_service=true
            break
        fi
    done

    if [ "$valid_service" = false ]; then
        echo -e "${RED}Error: Invalid service name '$1'${NC}"
        echo "Available services:"
        printf '%s\n' "${services[@]}"
        exit 1
    fi
    
    echo "Starting rebuild process for $1..."
    
    # 1. 서비스 중지
    echo -e "\n${YELLOW}1. Stopping $1...${NC}"
    ./stop.sh "$1"
    print_status "Stop service" $?

    sleep 5

    # 2. 빌드 실행
    echo -e "\n${YELLOW}2. Building $1...${NC}"
    ./build.sh "$1"
    print_status "Build service" $?

    # 3. 서비스 시작
    echo -e "\n${YELLOW}3. Starting $1...${NC}"
    ./start.sh "$1"
    print_status "Start service" $?

else
    echo "Starting rebuild process for all services..."

    # 1. 서비스 중지
    echo -e "\n${YELLOW}1. Stopping all services...${NC}"
    ./stop.sh
    print_status "Stop services" $?

    sleep 5

    # 2. 빌드 실행
    echo -e "\n${YELLOW}2. Building all services...${NC}"
    ./build.sh
    print_status "Build services" $?

    # 3. 서비스 시작
    echo -e "\n${YELLOW}3. Starting all services...${NC}"
    ./start.sh
    print_status "Start services" $?
fi

# 완료 메시지 및 경과 시간 출력
if [ $# -eq 1 ]; then
    echo -e "\n${GREEN}✓ Rebuild process completed successfully for $1${NC}"
else
    echo -e "\n${GREEN}✓ Rebuild process completed successfully for all services${NC}"
fi
show_elapsed_time

# 서비스 상태 확인
echo -e "\n${YELLOW}Checking service status...${NC}"
./status.sh

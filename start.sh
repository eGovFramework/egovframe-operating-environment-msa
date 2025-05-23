#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# MySQL 상태 확인 및 시작 함수
check_mysql() {
    echo "Checking MySQL status..."
    if docker compose -f ./docker-deploy/docker-compose.yml ps | grep -q mysql-com; then
        echo -e "${GREEN}MySQL is already running${NC}"
    else
        echo -e "${RED}MySQL is not running. Starting MySQL container...${NC}"
        
        # MySQL 컨테이너 시작
        docker compose -f ./docker-deploy/docker-compose.yml up -d mysql-com
        
        # MySQL 시작 대기 (healthcheck가 완료될 때까지)
        echo "Waiting for MySQL to be ready..."
        attempt=1
        max_attempts=30
        while [ $attempt -le $max_attempts ]; do
            if docker compose -f ./docker-deploy/docker-compose.yml ps mysql-com | grep -q "healthy"; then
                echo -e "${GREEN}MySQL is now ready${NC}"
                return 0
            fi
            echo "Attempt $attempt/$max_attempts: MySQL is not ready yet..."
            sleep 5
            attempt=$((attempt + 1))
        done
        
        echo -e "${RED}Failed to start MySQL. Please check the logs:${NC}"
        echo -e "${RED}docker compose -f ./docker-deploy/docker-compose.yml logs mysql-com${NC}"
        exit 1
    fi
}

# OpenSearch 시작 함수
start_opensearch() {
    echo "Checking OpenSearch status..."
    if docker compose ps | grep -q opensearch; then
        echo "OpenSearch is already running"
    else
        docker compose -f ./docker-deploy/docker-compose.yml up -d opensearch opensearch-dashboards
        echo "OpenSearch started"
    fi
}

# 로그 디렉토리 생성
mkdir -p logs

# MySQL 상태 확인
check_mysql

# OpenSearch 시작
start_opensearch

# 기본 서비스 순서 정의
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
    "EgovQuestionnaire"
    "EgovMobileId"
    "EgovSearch"
)

# 서비스의 프로파일 반환 함수
get_profile() {
    local service=$1
    case $service in
        "ConfigServer") echo "native" ;;
        "EurekaServer") echo "default" ;;
        "GatewayServer") echo "local" ;;
        *) echo "local" ;;
    esac
}

# 각 서비스 시작 함수
start_service() {
    local jar_path=$1
    local service_name=$(basename $jar_path .jar)
    local profile=${3:-local}
    
    # PID를 포함한 로그 파일 경로 생성
    local log_file="logs/${service_name}_$(date +%s).log"
    
    # 서비스 시작
    echo "Starting $service_name with profile '$profile'..."
    nohup java -jar "$jar_path" --spring.profiles.active="$profile" \
          > "$log_file" 2>&1 &
    
    # PID 획득
    local pid=$!
    
    # 프로세스가 시작되었는지 확인
    sleep 2
    if ps -p $pid > /dev/null; then
        # 로그 리다이렉션 시작
        echo -e "${GREEN}$service_name started successfully with PID: $pid${NC}"
        echo -e "${GREEN}Log file: $log_file${NC}"
        return 0
    else
        echo -e "${RED}Failed to start $service_name${NC}"
        return 1
    fi
}

# 서비스 존재 여부 확인 함수
is_valid_service() {
    local service=$1
    for s in "${core_services[@]}" "${services[@]}"; do
        if [ "$s" == "$service" ]; then
            return 0
        fi
    done
    return 1
}

# 코어 서비스 시작 함수
start_core_services() {
    # Config Server 시작
    if start_service "ConfigServer/target/ConfigServer.jar" "logs/ConfigServer.log" "native"; then
        echo -e "${GREEN}Config Server is available at: http://localhost:8888/application/local${NC}"
    else
        echo -e "${RED}Failed to start Config Server${NC}"
        exit 1
    fi
    sleep 10

    # Discovery Server 시작
    if start_service "EurekaServer/target/EurekaServer.jar" "logs/EurekaServer.log" "default"; then
        echo -e "${GREEN}Eureka Server Dashboard is available at: http://localhost:8761${NC}"
    else
        echo -e "${RED}Failed to start Eureka Server${NC}"
        exit 1
    fi
    sleep 20

    # Gateway 시작
    if start_service "GatewayServer/target/GatewayServer.jar" "logs/GatewayServer.log" "local"; then
        echo -e "${GREEN}Gateway Server started successfully${NC}"
    else
        echo -e "${RED}Failed to start Gateway Server${NC}"
        exit 1
    fi
    sleep 15
}

# 단일 서비스 시작 함수
start_single_service() {
    local service=$1
    local profile=$(get_profile "$service")
    
    # 코어 서비스가 아닌 경우 코어 서비스들이 실행 중인지 확인
    if [[ ! " ${core_services[@]} " =~ " ${service} " ]]; then
        for core_service in "${core_services[@]}"; do
            if ! pgrep -f "$core_service.jar" > /dev/null; then
                echo -e "${RED}Error: Core service $core_service is not running. Please start it first.${NC}"
                exit 1
            fi
        done
    fi
    
    start_service "$service/target/$service.jar" "logs/$service.log" "$profile"
    
    # EgovMain 서비스가 시작되면 접속 URL 표시
    if [ "$service" == "EgovMain" ]; then
        echo "EgovMain is available at: http://localhost:9000/"
    fi
}

# 메인 로직
if [ $# -eq 1 ]; then
    if [ "$1" == "mysql" ]; then
        # MySQL만 시작
        check_mysql
        echo -e "${GREEN}MySQL service has been started${NC}"
        exit 0
    fi

    # 서비스 이름이 유효한지 확인
    if ! is_valid_service "$1"; then
        echo -e "${RED}Error: Invalid service name '$1'${NC}"
        echo "Available services:"
        echo "Core services:"
        printf '%s\n' "${core_services[@]}"
        echo "Regular services:"
        printf '%s\n' "${services[@]}"
        exit 1
    fi

    # 특정 서비스 시작
    start_single_service "$1"
else
    # 모든 서비스 시작
    start_core_services

    # 나머지 서비스들 시작
    for service in "${services[@]}"; do
        if start_service "$service/target/$service.jar" "logs/$service.log"; then
            if [ "$service" == "EgovMain" ]; then
                echo -e "${GREEN}EgovMain is available at: http://localhost:9000/${NC}"
            fi
        else
            echo -e "${RED}Failed to start $service${NC}"
            exit 1
        fi
        sleep 5
    done
    echo -e "${GREEN}All services have been started. Check individual log files in logs/ directory${NC}"
fi

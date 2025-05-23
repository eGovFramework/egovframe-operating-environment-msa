#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 서비스 배열 정의
services=(
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
    "ConfigServer"
)

# 서비스 종료 함수
stop_service() {
    local service=$1
    echo "Stopping $service..."
    pid=$(pgrep -f $service)
    if [ ! -z "$pid" ]; then
        # 정상 종료 시도
        kill $pid
        sleep 2
        
        # 여전히 실행 중이면 강제 종료
        if ps -p $pid > /dev/null; then
            echo "Force stopping $service..."
            kill -9 $pid
        fi
        echo "$service stopped"
    else
        echo "$service is not running"
    fi
}

# MySQL 종료 함수
stop_mysql() {
    echo "Checking MySQL status..."
    if docker compose -f ./docker-deploy/docker-compose.yml ps | grep -q mysql-com; then
        echo "Stopping MySQL container..."
        docker compose -f ./docker-deploy/docker-compose.yml down mysql-com
        
        # MySQL 종료 확인
        if ! docker compose -f ./docker-deploy/docker-compose.yml ps | grep -q mysql-com; then
            echo -e "${GREEN}MySQL stopped successfully${NC}"
        else
            echo -e "${RED}Failed to stop MySQL${NC}"
            echo -e "${RED}Please check: docker compose -f ./docker-deploy/docker-compose.yml ps${NC}"
        fi
    else
        echo "MySQL is not running"
    fi
}

# OpenSearch 종료 함수
stop_opensearch() {
    echo "Checking OpenSearch status..."
    if docker compose -f ./docker-deploy/docker-compose.yml ps | grep -q opensearch; then
        echo "Stopping OpenSearch container..."
        docker compose -f ./docker-deploy/docker-compose.yml down opensearch opensearch-dashboards

        # OpenSearch 종료 확인
        if ! docker compose -f ./docker-deploy/docker-compose.yml ps | grep -q opensearch; then
            echo -e "${GREEN}OpenSearch stopped successfully${NC}"
        else
            echo -e "${RED}Failed to stop OpenSearch${NC}"
            echo -e "${RED}Please check: docker compose -f ./docker-deploy/docker-compose.yml ps${NC}"
        fi
    else
        echo "OpenSearch is not running"
    fi
}

# 인자가 있는 경우 해당 서비스만 종료
if [ $# -eq 1 ]; then
    # 서비스 이름이 유효한지 확인
    valid_service=false
    for service in "${services[@]}"; do
        if [ "$1" == "$service" ]; then
            valid_service=true
            break
        fi
    done

    if [ "$valid_service" = true ]; then
        stop_service "$1"
    else
        echo "Error: Invalid service name '$1'"
        echo "Available services:"
        printf '%s\n' "${services[@]}"
        exit 1
    fi
else
    # 인자가 없는 경우 모든 서비스 종료
    for service in "${services[@]}"; do
        stop_service "$service"
    done
    echo "All services have been stopped"
    
    # MySQL 종료
    stop_mysql

    # OpenSearch 종료
    stop_opensearch
fi

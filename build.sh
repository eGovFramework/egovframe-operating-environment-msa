#!/bin/bash

# ConfigServer application.yml 검증 함수
validate_config_server() {
    local config_file="ConfigServer/src/main/resources/application.yml"
    local default_path="file:/replace-with-your-config-path"
    
    if grep -q "$default_path" "$config_file"; then
        echo "Error: ConfigServer의 application.yml에서 search-locations가 기본값으로 설정되어 있습니다."
        echo "다음 경로를 실제 설정 저장소 경로로 변경해주세요:"
        echo "$default_path"
        echo "파일 경로: $config_file"
        return 1
    fi
    return 0
}

# EgovSearch password 검증 함수
validate_egovsearch_password() {
    local config_file="EgovSearch/src/main/resources/application.yml"
    local default_password="yourStrongPassword123!"
    
    if grep -q "password: $default_password" "$config_file"; then
        echo "Error: EgovSearch의 application.yml에서 OpenSearch 패스워드가 기본값으로 설정되어 있습니다."
        echo "다음 패스워드를 실제 사용할 패스워드로 변경해주세요:"
        echo "$default_password"
        echo "파일 경로: $config_file"
        return 1
    fi
    return 0
}

# 서비스 배열 정의
services=(
    "ConfigServer"
    "EgovAuthor"
    "EgovBoard"
    "EgovCmmnCode"
    "EgovHello"
    "EgovLogin"
    "EgovMain"
    "EgovMobileId"
    "EgovQuestionnaire"
    "EgovSearch"
    "EurekaServer"
    "GatewayServer"
)

# 서비스 빌드 함수
build_service() {
    local service=$1
    
    # ConfigServer 빌드 전 설정 검증
    if [ "$service" == "ConfigServer" ]; then
        if ! validate_config_server; then
            exit 1
        fi
    fi

    # EgovSearch 빌드 전 설정 검증
    if [ "$service" == "EgovSearch" ]; then
        if ! validate_egovsearch_password; then
            exit 1
        fi
    fi
    
    echo "Building $service..."
    cd $service && mvn clean package && cd ..
}

# 인자가 있는 경우 해당 서비스만 빌드
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
        build_service "$1"
    else
        echo "Error: Invalid service name '$1'"
        echo "Available services:"
        printf '%s\n' "${services[@]}"
        exit 1
    fi
else
    # 인자가 없는 경우 모든 서비스 빌드
    for service in "${services[@]}"; do
        build_service "$service"
    done
    echo "All services have been built"
fi

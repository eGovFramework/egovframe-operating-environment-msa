#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 시작 시간 기록
start_time=$(date +%s)

# 서비스 배열 정의
services=(
    "ConfigServer"
    "EurekaServer"
    "GatewayServer"
    "EgovAuthor"
    "EgovBoard"
    "EgovCmmnCode"
    "EgovLogin"
    "EgovLoginPolicy"
    "EgovMain"
    "EgovMobileId"
    "EgovQuestionnaire"
    "EgovSearch"
)

# 이미지 태그 정의
IMAGE_TAG="4.3.2"
K8S_TAG="k8s"

# 결과 저장을 위한 임시 파일
RESULT_FILE="/tmp/build_results.txt"
> $RESULT_FILE

# 빌드 함수
build_service() {
    local service=$1
    local build_type=$2
    echo -e "\n${BLUE}Building ${service}...${NC}"
    
    # 디렉토리 존재 확인
    if [ ! -d "$service" ]; then
        echo -e "${RED}Error: Directory $service not found${NC}"
        echo "${service}:Failed: Directory not found" >> $RESULT_FILE
        return 1
    fi
    
    # JAR 파일 존재 확인
    if [ ! -f "$service/target/"*.jar ]; then
        echo -e "${RED}Error: JAR file not found in $service/target/${NC}"
        echo "${service}:Failed: JAR file not found" >> $RESULT_FILE
        return 1
    fi

    # 서비스 디렉토리로 이동
    cd $service

    # Docker 이미지 빌드
    echo -e "${YELLOW}Building Docker image for $service...${NC}"
    image_name=$(echo $service | tr '[:upper:]' '[:lower:]')
    
    # k8s 빌드인 경우
    if [ "$build_type" == "k8s" ]; then
        tag=$K8S_TAG
        dockerfile="Dockerfile.k8s"
        if [ ! -f "$dockerfile" ]; then
            echo -e "${RED}Error: $dockerfile not found${NC}"
            cd ..
            echo "${service}:Failed: $dockerfile not found" >> $RESULT_FILE
            return 1
        fi
    else
        tag=$IMAGE_TAG
        dockerfile="Dockerfile"
    fi

    if ! docker build -f $dockerfile -t $image_name:$tag .; then
        echo -e "${RED}Docker build failed for $service${NC}"
        cd ..
        echo "${service}:Failed: Docker build failed" >> $RESULT_FILE
        return 1
    fi

    cd ..
    echo "${service}:Success" >> $RESULT_FILE
    echo -e "${GREEN}Successfully built $service${NC}"
    return 0
}

# 사용법 출력 함수
print_usage() {
    echo "Usage: $0 [OPTIONS] [SERVICE_NAME]"
    echo "Options:"
    echo "  -k, --k8s    Build images for Kubernetes deployment"
    echo "  -h, --help   Show this help message"
    echo ""
    echo "Available services:"
    printf '%s\n' "${services[@]}"
}

# 결과 출력 함수
print_summary() {
    echo -e "\n${BLUE}=== Build Summary ===${NC}"
    echo -e "Build started at: $(date -d @$start_time)"
    echo -e "Build finished at: $(date)"
    
    local duration=$(($(date +%s) - start_time))
    echo -e "Total build time: $((duration / 60))m $((duration % 60))s\n"
    
    echo -e "${BLUE}Build Results:${NC}"
    while IFS=: read -r service status; do
        if [ "$status" == "Success" ]; then
            echo -e "${GREEN}✓ $service: $status${NC}"
        else
            echo -e "${RED}✗ $service: $status${NC}"
        fi
    done < $RESULT_FILE
}

# 명령행 인자 파싱
BUILD_TYPE="default"
SERVICE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--k8s)
            BUILD_TYPE="k8s"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            SERVICE_NAME="$1"
            shift
            ;;
    esac
done

# Docker 네트워크 생성 (k8s 빌드가 아닌 경우에만)
if [ "$BUILD_TYPE" != "k8s" ]; then
    echo -e "${YELLOW}Checking Docker network...${NC}"
    if ! docker network ls | grep -q "egov-msa-com"; then
        echo -e "${YELLOW}Creating egov-msa-com...${NC}"
        docker network create egov-msa-com
    fi
fi

# 서비스 빌드 로직
if [ -n "$SERVICE_NAME" ]; then
    # 단일 서비스 빌드
    valid_service=false
    for service in "${services[@]}"; do
        if [ "$SERVICE_NAME" == "$service" ]; then
            valid_service=true
            break
        fi
    done

    if [ "$valid_service" = true ]; then
        echo -e "${BLUE}Starting build process for $SERVICE_NAME (Type: $BUILD_TYPE)...${NC}"
        build_service "$SERVICE_NAME" "$BUILD_TYPE"
    else
        echo -e "${RED}Error: Invalid service name '$SERVICE_NAME'${NC}"
        echo "Available services:"
        printf '%s\n' "${services[@]}"
        rm -f $RESULT_FILE
        exit 1
    fi
else
    # 모든 서비스 빌드
    echo -e "${BLUE}Starting build process for all services (Type: $BUILD_TYPE)...${NC}"
    echo -e "Services to build: ${services[@]}\n"

    for service in "${services[@]}"; do
        if [ "$BUILD_TYPE" != "k8s" ]; then
            build_service "$service" "$BUILD_TYPE"
        else
            if [ "$service" != "ConfigServer" ] && [ "$service" != "EurekaServer" ]; then
                build_service "$service" "$BUILD_TYPE"
            fi
        fi
    done
fi

# 빌드 결과 출력
print_summary

# 최종 상태 확인 및 결과 출력
FAILED=0
while IFS=: read -r service status; do
    if [ "$status" != "Success" ]; then
        FAILED=1
        break
    fi
done < $RESULT_FILE

# 임시 파일 삭제
rm -f $RESULT_FILE

if [ $FAILED -eq 1 ]; then
    echo -e "\n${RED}Some builds failed. Please check the build summary above.${NC}"
    exit 1
fi

echo -e "\n${GREEN}All services built successfully!${NC}"
if [ "$BUILD_TYPE" != "k8s" ]; then
    echo -e "You can now use 'docker-compose up' to start the services."
else
    echo -e "Kubernetes deployment images are ready."
fi

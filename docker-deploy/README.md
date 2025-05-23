# Docker 배포 가이드

## 사전 준비사항

- Docker Desktop 설치
- Docker Compose 설치
- 필요한 도구 설치 확인:
  ```bash
  docker version
  docker compose version
  ```

### 프로젝트 빌드

1. 전체 서비스 빌드
```bash
./build.sh
```

2. 도커 이미지 빌드
```bash
./docker-build.sh
```

3. OpenSearch 이미지 빌드
Nori 한글 형태소 분석기가 포함된 OpenSearch 이미지를 빌드해야 합니다:
```bash
docker build -t opensearch-with-nori:2.15.0 -f Dockerfile.opensearch .
```

## 환경 설정

### OpenSearch 구성
- 2개의 노드로 구성된 클러스터 (node1, node2)
- Nori 한글 형태소 분석기 포함
- 기본 포트:
  - OpenSearch: 9200 (HTTP), 9600 (Performance Analyzer)
  - Dashboards: 5601

### .env 파일 설정
프로젝트 루트의 `.env` 파일에서 다음 환경변수들을 설정할 수 있습니다:

```properties
# Network
NETWORK_NAME=egov-msa-com

# MySQL Configuration
MYSQL_HOST=mysql-com
MYSQL_PORT=3306
MYSQL_DATABASE=com
MYSQL_USER=com
MYSQL_PASSWORD=com01
MYSQL_ROOT_PASSWORD=com01

# Board Service Ports
EGOV_BOARD_PORT=8082
EGOV_BOARD_PORT_2=8092
EGOV_BOARD_PORT_3=8093

# Volume Paths
EGOVSEARCH_CONFIG_PATH=../EgovSearch-config/config
EGOVSEARCH_MODEL_PATH=../EgovSearch-config/model
EGOVSEARCH_CACERTS_PATH=../EgovSearch-config/cacerts
EGOVSEARCH_EXAMPLE_PATH=../EgovSearch-config/example
EGOVMOBILEID_CONFIG_PATH=../EgovMobileId/config

MYSQL_DATA_PATH=../k8s-deploy/data/mysql
OPENSEARCH_DATA_PATH=../k8s-deploy/data/opensearch
RABBITMQ_DATA_PATH=../k8s-deploy/data/rabbitmq
```

## 도커 서비스 실행

### Make 명령어 사용
```bash
# 전체 서비스 시작
make start

# 서비스 중지
make stop

# 게시판 서비스 스케일 아웃
make scale-out

# 게시판 서비스 스케일 다운
make scale-down
```

### Docker Compose 직접 사용
```bash
# 전체 서비스 시작
docker compose --env-file .env -f docker-compose.yml up -d

# 특정 서비스만 시작
docker compose --env-file .env -f docker-compose.yml up -d egov-main
docker compose --env-file .env -f docker-compose.yml up -d egov-board

# 게시판 서비스 스케일링
docker compose --env-file .env -f docker-compose.board-scale.yml up -d

# 서비스 중지
docker compose --env-file .env -f docker-compose.yml -f docker-compose.board-scale.yml down
```

## 서비스 접근

1. 접근 URL
- Gateway Server: http://localhost:9000/main/
- Config Server: http://localhost:8888/application/local
- Eureka Server: http://localhost:8761
- OpenSearch Dashboard: http://localhost:5601

2. 로그인 정보
- 일반 계정: USER/rhdxhd12
- 업무 계정: TEST1/rhdxhd12

## 서비스 중지 및 정리

1. 서비스 중지
```bash
docker-compose down
```

2. 특정 서비스만 중지
```bash
docker-compose stop egov-main
```

## 문제 해결

1. 컨테이너 상태 확인
```bash
docker ps -a
```

2. 컨테이너 로그 확인
```bash
docker logs [컨테이너ID 또는 이름]
```

3. 컨테이너 재시작
```bash
docker-compose restart [서비스명]
```

4. 네트워크 확인
```bash
docker network ls
docker network inspect egov-msa-com
```

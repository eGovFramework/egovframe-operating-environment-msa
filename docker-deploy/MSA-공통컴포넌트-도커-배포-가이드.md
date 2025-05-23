# 공통컴포넌트 MSA 도커 배포 가이드

## 1. 개요

### 시스템 요구사항

#### 하드웨어 요구사항
- CPU: 4코어 이상 권장
- RAM: 최소 16GB 이상 권장 (OpenSearch 클러스터 운영을 위해)
- 디스크: 최소 50GB 이상의 여유 공간
#### 소프트웨어 요구사항
- **운영체제**
  - Linux (Ubuntu 20.04 LTS 이상 권장)
  - macOS 12 이상
  - Windows 10/11 Pro 이상
  
- **필수 소프트웨어**
  - Docker Engine 24.0.0 이상
  - Docker Compose v2.20.0 이상
  - Java Development Kit (JDK) 17 이상
  - Git 2.34.1 이상

- **네트워크**
  - 인터넷 연결 (컨테이너 이미지 다운로드용)
  - 다음 포트들이 사용 가능해야 함:
    - 8761: Eureka Server
    - 8888: Config Server
    - 9000: API Gateway
    - 9200, 9600: OpenSearch
    - 5601: OpenSearch Dashboards
    - 3306: MySQL
    - 5672: RabbitMQ
    - 8081-8087: 마이크로서비스 포트 범위
#### 브라우저 요구사항
- Chrome 112.0 이상
- Firefox 113.0 이상
- Safari 16.0 이상
- Edge 112.0 이상
#### 권장 개발 도구
- IntelliJ IDEA 2023.1 이상 또는 Eclipse 2023-03 이상
- Visual Studio Code 1.78 이상
- Postman 10.0 이상 또는 Swagger UI (API 테스트용)
#### 컨테이너 리소스 권장사항
각 컨테이너의 권장 리소스:
- Config Server: 512MB RAM
- Eureka Server: 512MB RAM
- API Gateway: 512MB RAM
- OpenSearch: 4GB RAM (노드당)
- 마이크로서비스: 각 1GB RAM

> 참고: Docker Desktop 사용 시, 할당된 전체 리소스가 위 요구사항을 충족하도록 설정해야 합니다.
### 아키텍처 구성도
#### 전체 시스템 아키텍처
```mermaid
graph TB
    Client[클라이언트] --> Gateway[API Gateway :9000]
    
    subgraph "Infrastructure Services"
        Gateway --> Eureka[Service Discovery<br/>Eureka Server :8761]
        Gateway --> Config[Config Server :8888]
        Gateway --> RabbitMQ[RabbitMQ :5672]
    end
    
    subgraph "Data Stores"
        MySQL[(MySQL :3306)]
        OpenSearch[(OpenSearch<br/>:9200/:9300)]
        OpenSearchDash[OpenSearch<br/>Dashboard :5601]
    end
    
    subgraph "Microservices"
        Gateway --> Author[Author Service :8081]
        Gateway --> Board[Board Service :8082]
        Gateway --> Main[Main Service :8083]
        Gateway --> Login[Login Service :8084]
        Gateway --> MobileId[MobileId Service :8085]
        Gateway --> Code[Common Code<br/>Service :8086]
        Gateway --> Question[Questionnaire<br/>Service :8087]
        Gateway --> Search[Search Service :9992]
        
        Board --> MySQL
        Author --> MySQL
        Main --> MySQL
        Login --> MySQL
        MobileId --> MySQL
        Question --> MySQL
        Code --> MySQL
        Search --> OpenSearch
    end
    
    Eureka --> |Registry| Board
    Eureka --> |Registry| Author
    Eureka --> |Registry| Main
    Eureka --> |Registry| Login
    Eureka --> |Registry| MobileId
    Eureka --> |Registry| Question
    Eureka --> |Registry| Code
    Eureka --> |Registry| Search
    
    Config --> |Config| Board
    Config --> |Config| Author
    Config --> |Config| Main
    Config --> |Config| Login
    Config --> |Config| MobileId
    Config --> |Config| Question
    Config --> |Config| Code
    Config --> |Config| Search
```

#### 주요 컴포넌트 설명

1. **인프라 서비스**
   - **API Gateway (GatewayServer)**
     - 모든 클라이언트 요청의 단일 진입점
     - 라우팅, 로드밸런싱, 인증 처리
     - Spring Cloud Gateway 기반
   
   - **Service Discovery (Eureka Server)**
     - 마이크로서비스 등록 및 발견
     - 서비스 헬스체크
     - 동적 서비스 관리
   
   - **Config Server**
     - 중앙집중식 설정 관리
     - 환경별 설정 분리
     - 동적 설정 갱신

   - **RabbitMQ**
     - 이벤트 메시징
     - 설정 변경 전파
     - 서비스간 비동기 통신

2. **데이터 저장소**
   - **MySQL**
     - 주요 비즈니스 데이터 저장
     - 트랜잭션 처리
     - 관계형 데이터 관리
   
   - **OpenSearch**
     - 전문 검색 기능
     - 로그 수집 및 분석
     - 대시보드 시각화

3. **마이크로서비스**
   - **Board Service**: 게시판 관리
   - **Author Service**: 권한 관리
   - **Main Service**: 메인 화면 및 포털 기능
   - **Login Service**: 인증 및 로그인 처리
   - **MobileId Service**: 모바일 인증
   - **Questionnaire Service**: 설문조사
   - **Common Code Service**: 공통코드 관리
   - **Search Service**: 통합검색

#### 통신 흐름
1. 클라이언트 요청 → API Gateway
2. API Gateway에서 인증/인가 처리
3. Service Discovery를 통한 서비스 위치 확인
4. 해당 마이크로서비스로 요청 라우팅
5. 마이크로서비스에서 비즈니스 로직 처리
6. 데이터 저장소 접근 및 결과 반환
### 컨테이너 구성
#### 1. 기본 컨테이너 구성
| 컨테이너명 | 이미지 | 기본 포트 | 볼륨 마운트 | 의존성 |
|------------|--------|------------|--------------|---------|
| config-server | configserver:${IMAGE_TAG} | 8888 | ${CONFIG_LOCAL_PATH}:/config-repo | opensearch, bbs_rabbitmq |
| eureka-server | eurekaserver:${IMAGE_TAG} | 8761 | - | config-server |
| gateway-server | gatewayserver:${IMAGE_TAG} | 9000 | - | config-server, eureka-server |
| mysql-com | mysql:8.0 | 3306 | mysql_data:/var/lib/mysql | - |
| opensearch | opensearch-with-nori:2.15.0 | 9200, 9600 | opensearch-data1:/usr/share/opensearch/data | - |
| bbs_rabbitmq | rabbitmq:3-management | 5672, 15672 | rabbitmq_data:/var/lib/rabbitmq | - |

#### 2. 마이크로서비스 컨테이너
| 컨테이너명              | 이미지                            | 기본 포트 | 의존성                                   |
| ------------------ | ------------------------------ | ----- | ------------------------------------- |
| egov-author        | egovauthor:${IMAGE_TAG}        | 8081  | mysql-com, gateway-server             |
| egov-board         | egovboard:${IMAGE_TAG}         | 8082  | mysql-com, gateway-server             |
| egov-cmmncode      | egovcmmncode:${IMAGE_TAG}      | 8083  | mysql-com, gateway-server             |
| egov-login         | egovlogin:${IMAGE_TAG}         | 8084  | mysql-com, gateway-server             |
| egov-main          | egovmain:${IMAGE_TAG}          | 8085  | mysql-com, gateway-server             |
| egov-questionnaire | egovquestionnaire:${IMAGE_TAG} | 8087  | gateway-server                        |
| egov-search        | egovsearch:${IMAGE_TAG}        | 9992  | opensearch, mysql-com, gateway-server |

#### 3. 볼륨 구성
```yaml
volumes:
  opensearch-data1:    # OpenSearch 데이터 저장
    driver: local
    driver_opts:
      type: none
      device: ${OPENSEARCH_DATA_PATH}
      o: bind
      
  rabbitmq_data:      # RabbitMQ 데이터 저장
    driver: local
    driver_opts:
      type: none
      device: ${RABBITMQ_DATA_PATH}
      o: bind
      
  mysql_data:         # MySQL 데이터 저장
    driver: local
    driver_opts:
      type: none
      device: ${MYSQL_DATA_PATH}
      o: bind
```

#### 4. 네트워크 구성
- 네트워크명: `egov-msa-com`
- 타입: bridge
- 구성방식: 
  ```bash
  docker network create egov-msa-com
  ```

#### 5. 환경변수 구성
주요 환경변수 목록:
```properties
# 공통 설정
DOCKER_REGISTRY=localhost:5000
IMAGE_TAG=latest
NETWORK_NAME=egov-msa-com

# MySQL 설정
MYSQL_PORT=3306
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=com
MYSQL_USER=com
MYSQL_PASSWORD=com01

# RabbitMQ 설정
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_PORT=5672

# 서비스 포트
CONFIG_SERVER_PORT=8888
EUREKA_SERVER_PORT=8761
GATEWAY_SERVER_PORT=9000
```

#### 6. 스케일링 구성
Board 서비스의 수평적 확장 지원:
- egov-board-2: 포트 8092
- egov-board-3: 포트 8093
```yaml
services:
  egov-board-2:
    image: egovboard:${IMAGE_TAG}
    ports:
      - "${EGOV_BOARD_PORT_2:-8092}:${EGOV_BOARD_PORT:-8082}"
      
  egov-board-3:
    image: egovboard:${IMAGE_TAG}
    ports:
      - "${EGOV_BOARD_PORT_3:-8093}:${EGOV_BOARD_PORT:-8082}"
```

#### 7. 헬스체크 구성
모든 서비스는 다음과 같은 헬스체크 설정을 포함:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:${PORT}/actuator/health || exit 1
```

#### 8. 리소스 제한
컨테이너별 권장 리소스 제한:
```yaml
services:
  opensearch:
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 2G
          
  mysql-com:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

## 2. 사전 준비
### Docker 설치

#### Windows
1. Docker Desktop 설치
   - [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop) 다운로드
   - 시스템 요구사항:
     - Windows 10/11 Pro, Enterprise, Education (64-bit)
     - WSL 2 기능 활성화
     - 가상화 지원 (BIOS에서 활성화)
   - 설치 후 시스템 재시작

2. WSL 2 설치 (Windows Subsystem for Linux)
   ```powershell
   # PowerShell 관리자 모드에서 실행
   wsl --install
   ```

#### macOS
1. Docker Desktop 설치
   - [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop) 다운로드
   - 시스템 요구사항:
     - macOS 11 이상
     - Apple Silicon (M1~M4) 또는 Intel 프로세서
   ```bash
   # Homebrew를 통한 설치
   brew install --cask docker
   ```

#### Linux (Ubuntu/Debian)
```bash
# 이전 버전 제거
sudo apt-get remove docker docker-engine docker.io containerd runc

# 필요한 패키지 설치
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker 공식 GPG 키 추가
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker 리포지토리 설정
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 엔진 설치
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker 서비스 시작
sudo systemctl start docker
sudo systemctl enable docker

# 현재 사용자를 docker 그룹에 추가 (sudo 없이 실행)
sudo usermod -aG docker $USER
```

### Docker Compose 설치

#### Windows & macOS
- Docker Desktop 설치 시 Docker Compose가 자동으로 포함됨

#### Linux
```bash
# Docker Compose 플러그인 설치
sudo apt-get update
sudo apt-get install docker-compose-plugin

# 또는 직접 다운로드 설치
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 설치 확인
```bash
# Docker 버전 확인
docker --version
# 예상 출력: Docker version 24.0.6, build ed223bc

# Docker Compose 버전 확인
docker compose version
# 예상 출력: Docker Compose version v2.20.0

# Docker 실행 상태 확인
docker info

# Docker 테스트
docker run hello-world
```
   
### 프로젝트 클론

#### HTTPS 방식
```bash
# 프로젝트 클론
git clone https://github.com/your-organization/your-project.git

# 프로젝트 디렉토리로 이동
cd your-project
```

#### SSH 방식 (권장)
```bash
# SSH 키가 없는 경우 생성
ssh-keygen -t ed25519 -C "your-email@example.com"

# SSH 키 확인
cat ~/.ssh/id_ed25519.pub
# 출력된 키를 GitHub/GitLab의 SSH 키 설정에 등록

# 프로젝트 클론
git clone git@github.com:your-organization/your-project.git

# 프로젝트 디렉토리로 이동
cd your-project
```
#### 권한 설정
```bash
# 실행 권한 부여
chmod +x *.sh
chmod +x docker-deploy/*.sh
chmod +x k8s-deploy/scripts/**/*.sh

# 권한 확인
ls -la *.sh
```
### 환경 설정 파일 구성

#### .env 파일 확인
`docker-deploy`디렉토리에 `.env` 파일의 다음 설정을 확인합니다:

```properties
# MySQL Configuration
MYSQL_HOST=mysql-com
MYSQL_PORT=3306
MYSQL_DATABASE=com
MYSQL_USER=com
MYSQL_PASSWORD=com01
MYSQL_ROOT_PASSWORD=com01

# Service Ports
EGOV_BOARD_PORT=8082
EGOV_BOARD_PORT_2=8092
EGOV_BOARD_PORT_3=8093

# Volume Path Configuration
EGOVSEARCH_CONFIG_PATH=../EgovSearch-config/config
EGOVSEARCH_MODEL_PATH=../EgovSearch-config/model
EGOVSEARCH_CACERTS_PATH=../EgovSearch-config/cacerts
EGOVSEARCH_EXAMPLE_PATH=../EgovSearch-config/example
EGOVMOBILEID_CONFIG_PATH=../EgovMobileId/config

# Data Persistence Paths
MYSQL_DATA_PATH=../k8s-deploy/data/mysql
OPENSEARCH_DATA_PATH=../k8s-deploy/data/opensearch
RABBITMQ_DATA_PATH=../k8s-deploy/data/rabbitmq

# Docker Image Configuration
IMAGE_TAG=latest
SPRING_PROFILES_ACTIVE_DEFAULT=docker
CONFIG_SERVER_PORT=8888
```
#### EgovMobileId 설정
`docker-deploy/docker-compose.yml`의 관련 설정을 보면:
```
  egov-mobileid:
    environment:
      - APP_VERIFY_FILE_PATH=/app/config/verifyConfig-docker.json
    volumes:
      - ${EGOVMOBILEID_CONFIG_PATH}:/app/config:ro
```
이 설정의 동작 방식은 다음과 같습니다:

1. **볼륨 마운트**:
    - `${EGOVMOBILEID_CONFIG_PATH}:/app/config:ro`
    - 호스트의 `EGOVMOBILEID_CONFIG_PATH` 경로(예: `../EgovMobileId/config`)가 컨테이너의 `/app/config` 디렉토리로 마운트됩니다.
    - `:ro`는 read-only 마운트를 의미합니다.
2. **설정 파일 경로**:
    - `APP_VERIFY_FILE_PATH=/app/config/verifyConfig-docker.json`
    - 애플리케이션이 참조하는 설정 파일의 컨테이너 내부 경로입니다.
3. 실제 파일 구조
```
호스트 시스템:
../EgovMobileId/config/
    ├── verifyConfig-docker.json
    ├── sp.wallet
    └── sp.did

컨테이너 내부:
/app/config/
    ├── verifyConfig-docker.json
    ├── sp.wallet
    └── sp.did
```

`EgovMobileId/config` 디렉토리에 다음 파일들을 확인합니다:

4. `verifyConfig-docker.json` 설정
```json
{
    "blockchain": {
        "account": "egovframe.sp",
        "serverDomain": "https://bcdev.mobileid.go.kr:18888",
        "connectTimeout": "3000",
        "readTimeout": "3000",
        "useCache": true,
        "sdkDetailLog": true
    },
    "didWalletFile": {
        "keymanagerPath": "/app/config/sp.wallet",
        "keymanagerPassword": "egovframe",
        "signKeyId": "omni.sp",
        "encryptKeyId": "omni.sp.rsa",
        "didFilePath": "/app/config/sp.did"
    },
    "sp": {
        "serverDomain": "http://61.253.112.177:9991",
        "biImageUrl": "https://www.mobileId.go.kr/resources/images/main/mdl_ico_homepage.ico"
    }
}
```

5. 필수 파일 구성
- `sp.wallet`: 전자지갑 파일
- `sp.did`: DID 파일

#### EgovSearch 설정
`docker-deploy/docker-compose.yml`의 관련 설정을 보면:
```
  egov-search:
    environment:
      - APP_SEARCH_CONFIG_PATH=/app/config/searchConfig-docker.json
      - OPENSEARCH_KEYSTORE_PATH=/opt/java/openjdk/lib/security/cacerts
    volumes:
      - ${EGOVSEARCH_CONFIG_PATH}:/app/config:ro
      - ${EGOVSEARCH_MODEL_PATH}:/app/model
      - ${EGOVSEARCH_CACERTS_PATH}:/app/cacerts:ro
      - ${EGOVSEARCH_EXAMPLE_PATH}:/app/example
```
이 설정의 동작 방식은 다음과 같습니다:

1. **볼륨 마운트 구조**:
```
호스트 시스템:
../EgovSearch-config/
    ├── config/
    │   └── searchConfig-docker.json
    ├── model/
    │   ├── model.onnx
    │   └── tokenizer.json
    ├── cacerts/
    │   └── cacerts
    └── example/
        ├── stoptags.txt
        ├── synonyms.txt
        └── dictionaryRules.txt

컨테이너 내부:
/app/
    ├── config/
    │   └── searchConfig-docker.json
    ├── model/
    │   ├── model.onnx
    │   └── tokenizer.json
    ├── cacerts/
    │   └── cacerts
    └── example/
        ├── stoptags.txt
        ├── synonyms.txt
        └── dictionaryRules.txt
```
2. **각 볼륨의 목적**:
    - `config`: 검색 설정 파일 (읽기 전용)
    - `model`: ML 모델 파일
    - `cacerts` : SSL 인증서 (읽기 전용)
    - `example`: 사전 및 규칙 파일

`EgovSearch-config` 디렉토리에 다음 구성을 확인합니다:

3. `config/searchConfig-docker.json` 설정
```json
{
    "modelPath": "/app/model/model.onnx",
    "tokenizerPath": "/app/model/tokenizer.json",
    "stopTagsPath": "/app/example/stoptags.txt",
    "synonymsPath": "/app/example/synonyms.txt",
    "dictionaryRulesPath": "/app/example/dictionaryRules.txt"
}
```
`EgovSearch/Dockerfile` 에서 SSL 인증서 파일을 JDK 보안 디렉토리로 복사 후 JAR 파일이 실행되도록 구성합니다.
```Dockerfile
# 기본 이미지 설정
FROM eclipse-temurin:17-jre-jammy
...

# 시작 스크립트 생성
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'cp /app/cacerts/* /opt/java/openjdk/lib/security/' >> /app/start.sh && \
    echo 'exec java -jar /app/app.jar' >> /app/start.sh && \
    chmod +x /app/start.sh

...

# 시작 명령어
ENTRYPOINT ["/app/start.sh"]
```
#### 데이터 디렉토리 생성
영구 저장소로 사용할 디렉토리들을 생성합니다:
```bash
# 데이터 디렉토리 생성
mkdir -p k8s-deploy/data/{mysql,opensearch,rabbitmq}

# 권한 설정
chmod -R 777 k8s-deploy/data
```
## 3. 빌드 및 배포
### 3.1 프로젝트 빌드
#### 3.1.1 전체 서비스 빌드

모든 서비스를 한 번에 빌드하려면 다음 명령어를 실행합니다:
```bash
./build.sh
```

빌드가 완료되면 각 서비스의 `target` 폴더에 jar 파일이 생성됩니다.

#### 3.1.2 특정 서비스 빌드

특정 서비스만 빌드하려면 서비스 이름을 인자로 전달합니다:
```bash
./build.sh EgovMain
./build.sh EgovBoard
```
#### 3.1.3 빌드 결과 확인

1. JAR 파일 확인
```bash
# 각 서비스의 target 폴더에서 jar 파일 존재 여부 확인
ls */target/*.jar
```
### 3.2 Docker 이미지 빌드

#### 3.2.1  OpenSearch 이미지 빌드 (Nori 플러그인 포함)
`EgovSearch/docker-compose/Opensearch/Dockerfile`를 살펴보면,
```Dockerfile
FROM opensearchproject/opensearch:2.15.0
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch analysis-nori
```
OpenSearch의 공식 이미지에 Nori 한글 형태소 분석기 플러그인을 설치하고 있습니다. 
`--batch` 옵션은 사용자 입력을 요구하지 않고 자동으로 진행합니다.

Nori 한글 형태소 분석기가 포함된 OpenSearch 이미지를 빌드해야 합니다:
```bash
cd EgovSearch/docker-compose/Opensearch
docker build -t opensearch-with-nori:2.15.0 -f Dockerfile.opensearch .
```
#### 3.2.2   전체 서비스 이미지 빌드
```bash
./docker-build.sh
```
#### 3.2.3   특정 서비스 이미지만 빌드
```bash
./docker-build.sh EgovMain
```
#### 3.2.4 Docker 이미지 확인
```bash
# 빌드된 이미지 목록 확인
docker images | grep latest
```

### 3.3 컨테이너 실행

#### 3.3.1 기본 실행
전체 서비스를 기본 설정으로 실행:
```bash
make start
```
실행 후 접속 가능한 주소:
- Gateway Server: http://localhost:9000/main/
- Config Server: http://localhost:8888/application/local
- Eureka Server: http://localhost:8761
- OpenSearch Dashboard: http://localhost:5601
#### 3.3.2 서비스 스케일링
게시판 서비스 확장/축소:
```bash
# 게시판 서비스 스케일 아웃 (2개 인스턴스 추가)
make scale-out

# 게시판 서비스 스케일 다운 (추가 인스턴스 제거)
make scale-down
```
#### 3.3.3 서비스 중지
```bash
# 전체 서비스 중지
make stop
```
#### 3.3.4 개별 서비스 관리
Docker Compose 명령어를 직접 사용하여 개별 서비스 관리:
```bash
# 특정 서비스만 시작
docker compose --env-file .env -f docker-compose.yml up -d egov-main
docker compose --env-file .env -f docker-compose.yml up -d egov-board

# 특정 서비스만 중지
docker compose --env-file .env -f docker-compose.yml stop egov-main

# 특정 서비스만 재시작
docker compose --env-file .env -f docker-compose.yml restart egov-main
```

#### 3.3.5 상태 확인
```bash
# 실행 중인 컨테이너 목록
docker ps

# 특정 서비스 로그 확인
docker logs [컨테이너ID 또는 이름]

# 특정 서비스 로그 실시간 확인
docker logs -f [컨테이너ID 또는 이름]

# 헬스체크 상태 확인
docker ps --format "table {{.Names}}\t{{.Status}}"
```
#### 3.3.6 문제 해결

1. 컨테이너 시작 실패 시
```bash
# 로그 확인
docker logs [컨테이너ID 또는 이름]

# 컨테이너 상태 확인
docker inspect [컨테이너ID 또는 이름]
```

2. 네트워크 문제 발생 시
```bash
# 네트워크 목록 확인
docker network ls

# 네트워크 상세 정보 확인
docker network inspect egov-msa-com
```

3. 볼륨 문제 발생 시
```bash
# 볼륨 목록 확인
docker volume ls

# 볼륨 상세 정보 확인
docker volume inspect [볼륨명]
```
### 3.4 서비스 확인

#### 3.4.1. 서비스 상태 확인

1) Eureka 서버 확인
- URL: http://localhost:8761
- 확인사항:
  * 모든 마이크로서비스가 정상적으로 등록되었는지 확인
  * 서비스 상태(UP/DOWN) 확인
  * 인스턴스 수 확인

2) Config 서버 확인
- URL: http://localhost:8888/application/local
- 확인사항:
  * 설정 정보가 정상적으로 로드되었는지 확인
  * 환경별(local, docker, default) 설정 확인

3) Gateway 서버 확인
- URL: http://localhost:9000/main/
- 확인사항:
  * 메인 페이지 접속 가능 여부
  * 라우팅 정상 작동 여부
  * 로그인 기능 정상 작동 여부
  * 계정: USER/rhdxhd12 (일반 사용자)
  * 계정: TEST1/rhdxhd12 (업무 사용자)
  * 각 업무 서비스 확인

#### 3.4.2. 개별 서비스 확인

1) 모니터링 도구
- OpenSearch Dashboard
	* URL: http://localhost:5601
	* 인덱스 상태 확인
	* 로그 수집 현황 확인
1) RabbitMQ
- 접속 정보:
	* URL: http://localhost:15672
	* 계정: guest/guest (기본 계정)
1) Swagger 서비스 확인
- 인덱스 관리 API
	- URL: http://localhost:9992/swagger-ui/index.html#/
	- 텍스트 인덱스 생성: GET /ext/ops/createTextIndex
		* 설명: 게시판 텍스트 검색용 인덱스 생성
		* 기본 인덱스명: text-bbs-index
	- 벡터 인덱스 생성: GET /ext/ops/createVectorIndex
		* 설명: 게시판 벡터 검색용 인덱스 생성
		* 기본 인덱스명: vector-bbs-index
	- 인덱스 삭제: GET /ext/ops/deleteIndex
		* 설명: 지정된 인덱스 삭제
		* 파라미터: indexName (삭제할 인덱스명)
- 데이터 관리 API
	- 텍스트 데이터 입력: GET /ext/ops/insertTextData
	- 벡터 데이터 입력: GET /ext/ops/insertVectorData
- 검색 API
	- 텍스트 검색: POST /ext/ops/textSearchResultView
	- 벡터 검색: POST /ext/ops/vectorSearchResultView

#### 3. 헬스체크 엔드포인트

각 서비스의 상태를 개별적으로 확인:
```bash
# Gateway 서버 헬스체크
curl http://localhost:9000/actuator/health

# Config 서버 헬스체크
curl http://localhost:8888/actuator/health

# 메인 서비스 헬스체크
curl http://localhost:9000/main/actuator/health
```
#### 4. 로그 확인

2) 컨테이너 로그
```bash
# 전체 서비스 로그
docker compose logs

# 특정 서비스 로그
docker compose logs egov-main
docker compose logs egov-board
```
#### 5. 문제 해결 가이드

3) 서비스 접속 불가 시
```bash
# 1. 컨테이너 상태 확인
docker ps -a

# 2. 네트워크 상태 확인
docker network inspect egov-msa-com
docker network inspect egov-msa-com_opensearch-net

# 3. 로그 확인
docker logs [컨테이너ID]
```

4) 데이터베이스 연결 오류
```bash
# 1. MySQL 컨테이너 상태 확인
docker compose ps mysql-com

# 2. MySQL 로그 확인
docker compose logs mysql-com
```

5) 설정 서버 문제
```bash
# 1. Config 서버 로그 확인
docker compose logs config-server

# 2. 설정 파일 경로 확인
docker exec config-server ls /config-repo
```
## 4. 서비스 구성
### 4.1 Config Server

#### 4.1.1 개요
- 역할: 중앙 집중식 설정 관리 서버
- 포트: 8888
- 프로파일: native, default

#### 4.1.2 주요 구성
6) 애플리케이션 설정
```yaml
server:
  port: 8888

spring:
  application:
    name: ConfigServer
  profiles:
    active: native
  cloud:
    config:
      server:
        native:
          search-locations: classpath:/config
```
- `docker-deploy/docker-compose.yml` 에서 `SPRING_PROFILES_ACTIVE=native`로 설정한 이유는 Config Server가 설정 파일을 로드하는 방식과 관련이 있습니다.
```yml
  config-server:
    environment:
      - SPRING_PROFILES_ACTIVE=native
      - SPRING_CLOUD_CONFIG_SERVER_NATIVE_SEARCH_LOCATIONS=file:/config-repo
    volumes:
      - ../ConfigServer-config:/config-repo
```
-  Native 프로파일의 특징:
    - 로컬 파일 시스템에서 직접 설정 파일을 읽음
    - Git 저장소 없이도 설정 파일 관리 가능
    - Docker 환경에서 볼륨 마운트를 통해 설정 파일 관리 용이

7) 설정 파일 구조
```
ConfigServer-config/
├── application.yml         # 공통 설정
├── application-local.yml   # 로컬 환경 설정
└── application-docker.yml  # 도커 환경 설정
```
- 위와 같이 프로파일별로 파일을 구성할 수 있고, 다음과 같이 하나의 `application.yml`에 프로파일별로 설정할 수 있습니다.
8. `---`로 각 섹션을 구분
9. `spring.config.activate.on-profile`로 프로파일 지정
```yml
# 공통 설정 (모든 프로파일에 적용)
datasource:
  driver-class-name: com.mysql.cj.jdbc.Driver
  hikari:
    maximum-pool-size: 20

spring:
  rabbitmq:
    port: 5672
    username: guest
    password: guest

---
# local 프로파일 설정
spring:
  config:
    activate:
      on-profile: local  # 프로파일 구분자
  rabbitmq:
    host: localhost

datasource:
  url: jdbc:mysql://localhost:3306/com
  username: com
  password: com01

---
# docker 프로파일 설정
spring:
  config:
    activate:
      on-profile: docker  # 프로파일 구분자
  rabbitmq:
    host: bbs_rabbitmq

datasource:
  url: jdbc:mysql://mysql-com:3306/com
  username: com
  password: com01
```
#### 4.1.3 주요 기능
10) 공통 설정 관리
- 데이터베이스 연결 정보
- 토큰 설정
- 권한 설정
- RabbitMQ 설정

11) 환경별 설정 관리
- Local 환경: localhost 기반 설정
- Docker 환경: 컨테이너 기반 설정

#### 4.1.4 설정 조회 방법
12) REST API
```bash
# 기본 설정 조회
curl http://localhost:8888/{application-name}/default

# 특정 프로파일 설정 조회
curl http://localhost:8888/{application-name}/{profile}

# 예시
curl http://localhost:8888/EgovBoard/local
```

13) Actuator 엔드포인트
```bash
# 설정 서버 상태 확인
curl http://localhost:8888/actuator/health

# 환경 정보 확인
curl http://localhost:8888/actuator/env
```

#### 4.1.5 클라이언트 설정
14) 의존성 추가
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-config</artifactId>
</dependency>
```

15) 클라이언트 설정 예시
```yaml
spring:
  config:
    import: optional:configserver:http://localhost:8888
  profiles:
    active: docker
```

#### 4.1.6 보안 설정
16) 설정 파일 암호화
- 민감한 정보(비밀번호, 키 등) 암호화 지원
- 대칭/비대칭 암호화 지원

17) 접근 제어
- Basic 인증 설정
- Spring Security 통합

#### 4.1.7 모니터링
18) 상태 확인
```bash
# 헬스체크
curl http://localhost:8888/actuator/health

# 설정 갱신 이력
curl http://localhost:8888/actuator/refresh
```

19) 로그 확인
```bash
# 도커 환경
docker logs config-server

# 로컬 환경
tail -f logs/config-server.log
```
### 4.2 Service Discovery (Eureka)

#### 4.2.1 개요
- 역할: 서비스 등록 및 발견
- 포트: 8761
- 기본 URL: http://localhost:8761

#### 4.2.2 주요 구성

20) Eureka Server 설정
```yaml
# application.yml
server:
  port: 8761

spring:
  application:
    name: EurekaServer

eureka:
  client:
    register-with-eureka: false  # 자신을 등록하지 않음
    fetch-registry: false        # 레지스트리 정보를 로컬에 캐싱하지 않음
  server:
    peer-node-read-timeout-ms: 10000
```

21) Eureka Client 설정
```yaml
# 각 마이크로서비스의 application.yml
eureka:
  client:
    register-with-eureka: true  # Eureka 서버에 서비스 등록
    fetch-registry: true        # Eureka 서버로부터 서비스 목록 가져오기
    registry-fetch-interval-seconds: 5  # 서비스 목록 갱신 주기
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
  instance:
    instance-id: ${spring.application.name}:${random.value}
    leaseRenewalIntervalInSeconds: 5    # 하트비트 전송 주기
    leaseExpirationDurationInSeconds: 10 # 서비스 만료 시간
```

#### 4.2.3 환경별 설정

22) Local 환경
```yaml
eureka:
  client:
    service-url:
      defaultZone: http://admin:admin@localhost:8761/eureka
```

23) Docker 환경
```yaml
eureka:
  client:
    service-url:
      defaultZone: http://admin:admin@eureka-server:8761/eureka
```

24) K8s 환경
- Eureka 비활성화
```yaml
spring:
  cloud:
    config:
      enabled: false
	discovery:
      enabled: false
eureka:
  client:
    enabled: false
```

#### 4.2.4 서비스 등록 방법

25) 의존성 추가
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

26) 애플리케이션 설정
```java
@SpringBootApplication
@EnableDiscoveryClient
public class EgovServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(EgovServiceApplication.class, args);
    }
}
```

#### 4.2.5 서비스 조회 방법

27) Eureka Dashboard
- 접속 URL: http://localhost:8761
- 등록된 서비스 목록 확인
- 서비스 상태 모니터링

28) REST API
```bash
# 서비스 목록 조회
curl http://localhost:8761/eureka/apps

# 특정 서비스 조회
curl http://localhost:8761/eureka/apps/{SERVICE-NAME}
```

### 4.3 API Gateway

#### 4.3.1 개요
- 역할: 라우팅, 인증, 로드밸런싱, 서킷브레이커
- 포트: 9000
- 기술스택: Spring Cloud Gateway

#### 4.3.2 주요 기능

29) 라우팅
```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: EgovMain
          uri: ${service.uri.main}
          predicates:
            - Path=/main/**
          filters:
            - RewritePath=/main/(?<segment>.*), /${segment}
            - name: CircuitBreaker
              args:
                name: mainCircuitBreaker
                fallbackUri: forward:/fallback/main
```

30) 인증 필터
```java
@Component
public class AuthGatewayFilterFactory extends AbstractGatewayFilterFactory<Config> {
    @Override
    public GatewayFilter apply(Config config) {
        return (exchange, chain) -> {
            // JWT 토큰 검증
            // 권한 체크
            // 헤더 설정
            return chain.filter(exchange);
        };
    }
}
```

31) 로드밸런싱
```yaml
# Local/Docker 환경
service:
  uri:
    main: lb://EGOVMAIN    # Eureka 서비스 ID 사용
    board: lb://EGOVBOARD

# K8s 환경
service:
  uri:
    main: http://egov-main.egov-app.svc.cluster.local  # K8s 서비스 이름 사용
    board: http://egov-board.egov-app.svc.cluster.local
```

32) 서킷브레이커
```yaml
resilience4j:
  circuitbreaker:
    configs:
      default:
        slidingWindowSize: 10
        failureRateThreshold: 50
        waitDurationInOpenState: 10000
        permittedNumberOfCallsInHalfOpenState: 3
    instances:
      mainCircuitBreaker:
        baseConfig: default
```

#### 4.3.3 환경별 설정

33) Local/Docker 환경
- Eureka 서비스 디스커버리 사용
- lb:// 스키마로 로드밸런싱

34) K8s 환경
- K8s 서비스 디스커버리 사용
- 서비스 DNS 이름으로 직접 라우팅

#### 4.3.4 보안 설정

35) JWT 인증
```java
@Configuration
public class GatewayJwtProvider {
    public int accessValidateToken(String token) {
        // 토큰 유효성 검증
    }

    public ServerHttpRequest headerSetting(ServerWebExchange exchange, String accessToken) {
        // 인증 정보 헤더 설정
    }
}
```
1) JWT 설정 값 (application.yml)
```yaml
token:
  accessSecret: "7FB814B9D7FFB3D675EF1F525C1D61B254227B3B0A771DDDBDFE4112A1F42F66"
  refreshSecret: "7FB814B9D7FFB3D675EF1F525C1D61B254227B3B0A771DDDBDFE4112A1F42F66"
  accessExpiration: 1200000  # 20분
  refreshExpiration: 3600000 # 60분
```
- **Access Token 생성/검증용 시크릿 키**
    - 짧은 수명의 토큰(현재 설정: 20분 - `accessExpiration: 1200000`)을 서명하는데 사용
    - API 요청 인증에 직접 사용되는 토큰을 생성/검증
    - 실제 리소스 접근 권한을 부여하는 토큰의 무결성 보장
- **Refresh Token 생성/검증용 시크릿 키**
    - 긴 수명의 토큰(현재 설정: 60분 - `refreshExpiration: 3600000`)을 서명하는데 사용
    - Access Token이 만료되었을 때 새로운 Access Token을 발급받는데 사용
    - 사용자가 매번 로그인하지 않아도 되도록 하는 토큰의 무결성 보장

1) CORS 설정
```yaml
spring:
  cloud:
    gateway:
      globalcors:
        cors-configurations:
          '[/**]':
            allowed-origins: 
              - http://localhost:9000
            allowedMethods:
              - GET
              - POST
              - PUT
              - DELETE
            allowedHeaders: "*"
            allowCredentials: true
```

#### 4.3.5 모니터링

2) Actuator 엔드포인트
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, metrics, gateway
```

3) 로깅 설정
```yaml
logging:
  level:
    org.springframework.cloud.gateway: DEBUG
    reactor.netty: DEBUG
```

#### 4.3.6 에러 처리

4) 폴백 처리
```java
@Component
public class FallbackController {
    @GetMapping("/fallback/{service}")
    public Mono<String> fallback(@PathVariable String service) {
        // 서비스별 폴백 처리
    }
}
```

5) 에러 응답 포맷
```java
public class ErrorResponse {
    private String code;
    private String message;
    private LocalDateTime timestamp;
}
```

#### 4.3.7 성능 최적화

6) 타임아웃 설정
```yaml
spring:
  cloud:
    gateway:
      httpclient:
        connect-timeout: 2000
        response-timeout: 5s
```

7) 버퍼 설정
```yaml
spring:
  cloud:
    gateway:
      httpserver:
        max-initial-line-length: 10485760
        max-header-size: 10485760
```

#### 4.3.8 주의사항

8) 운영 환경
- 적절한 타임아웃 설정
- 서킷브레이커 임계값 조정
- 로깅 레벨 관리

9) 보안
- JWT 시크릿 키 관리
- CORS 설정 검토
- 헤더 보안 설정
### 4.4 OpenSearch

#### 4.4.1 개요
- 역할: 전문 검색 엔진
- 포트: 9200 (REST API), 9600 (Performance Analyzer)
- 버전: OpenSearch 2.15.0
- 플러그인: analysis-nori (한글 형태소 분석)

#### 4.4.2 클러스터 구성 (싱글)

10) Docker Compose 설정
```yaml
volumes:
  opensearch-data1:
    driver: local
    driver_opts:
      type: none
      device: ../k8s-deploy/data/opensearch
      o: bind
services:
  opensearch-node1:
    image: opensearch-with-nori:2.15.0
    container_name: opensearch
    environment:
      - discovery.type=single-node
      - OPENSEARCH_JAVA_OPTS=-Xms1024m -Xmx1024m
      - bootstrap.memory_lock=true
      - OPENSEARCH_INITIAL_ADMIN_PASSWORD=${OPENSEARCH_INITIAL_ADMIN_PASSWORD}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - opensearch-data1:/usr/share/opensearch/data
```
- 볼륨 구성
	- 호스트 경로: `../k8s-deploy/data/opensearch`
	- 컨테이너 마운트 경로: `/usr/share/opensearch/data`
	- 마운트 타입: bind mount (호스트 디렉토리 직접 연결)

- 볼륨 설정 특징
	- `driver: local`: 로컬 스토리지 사용
	- `type: none`, `o: bind`: 호스트 디렉토리를 직접 마운트
	- 컨테이너가 재시작되어도 데이터 유지

11) 노리 플러그인 설치 (한글 형태소 분석기) Dockerfile 로 이미지 빌드
```dockerfile
FROM opensearchproject/opensearch:2.15.0
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch analysis-nori
```
- 설정 설명
	- 기본 이미지: OpenSearch 2.15.0 버전 사용
	- Nori 플러그인: 한글 형태소 분석을 위한 필수 플러그인
	- `--batch` 옵션: 플러그인 설치 시 사용자 입력 없이 자동 진행
- 이미지 빌드
	- `docker build -t opensearch-with-nori:2.15.0 -f Dockerfile.opensearch .`
#### 4.4.3 인덱스 설정

12) 텍스트 인덱스
```java
private void addMappings(CreateIndexRequest.Builder builder, boolean includeVector) {
    builder.mappings(mapping -> {
        TypeMapping.Builder mappingBuilder = mapping
                .properties("nttId",
                        p -> p.integer(f -> f.index(true)
                                .fields("keyword", k -> k.keyword(kw -> kw.ignoreAbove(256)))))
                .properties("nttSj",
                        p -> p.text(f -> f.index(true).analyzer("nori-analyzer")))
                .properties("nttCn",
                        p -> p.text(f -> f.index(true).analyzer("nori-analyzer")));
        return mappingBuilder;
    });
}
```

13) 벡터 인덱스
```java
mappingBuilder = mappingBuilder.properties("bbsArticleVector",
        p -> p.knnVector(k -> k.dimension(768)));
```

#### 4.4.4 OpenSearch 클라이언트(EgovSearch) 설정
Spring Boot 애플리케이션에서 OpenSearch를 안전하게 연결하고 사용하기 위한 기본 구성을 제공합니다.

14) Maven 의존성 설정
```xml
<dependency>
	<groupId>org.opensearch.client</groupId>
	<artifactId>opensearch-java</artifactId>
	<version>2.8.1</version>
	<exclusions>
		<exclusion>
			<groupId>org.apache.httpcomponents.core5</groupId>
			<artifactId>httpcore5</artifactId>
		</exclusion>
	</exclusions>
</dependency>
```

15) 애플리케이션 설정
```yaml
opensearch:
  protocol: https
  url: localhost
  port: 9200
  username: admin
  password: admin
  keystore:
    path: ${OPENSEARCH_KEYSTORE_PATH:/path/to/keystore}
    password: changeit
  text:
    indexname: text-bbs-index
  vector:
    indexname: vector-bbs-index
```

#### 4.4.5 데이터 처리

16) 데이터 삽입/수정
```java
public void processOpenSearchOperations(Long nttId, BoardVO boardVO) {
    performOpenSearchTextOperation(nttId, boardVO);
    performOpenSearchVectorOperation(nttId, boardVO);
}
```

17) 벌크 처리
```java
private void processBatchRequest(List<BbsDTO> batchData, boolean withVector, 
        String indexName, int currentPage, int totalPages) {
    BulkRequest.Builder bulkRequestBuilder = new BulkRequest.Builder();
    batchData.forEach(bbsArticleInfo -> {
        Map<String, Object> dataMap = convertToMap(bbsArticleInfo, withVector);
        bulkRequestBuilder.operations(ops -> ops
                .index(idx -> idx.index(indexName)
                .id(String.valueOf(dataMap.get("nttId")))
                .document(dataMap)));
    });
}
```

#### 4.4.6 검색 기능

18) 텍스트 검색
```java
SearchRequest searchRequest = new SearchRequest.Builder()
    .index(textIndexName)
    .query(q -> q
        .multiMatch(m -> m
            .fields("nttSj^2", "nttCn")
            .query(searchText)
            .analyzer("nori-analyzer")))
    .build();
```

19) 벡터 검색
```java
float[] queryVector = embeddingModel.embed(searchText).content().vector();
SearchRequest searchRequest = new SearchRequest.Builder()
    .index(vectorIndexName)
    .query(q -> q
        .knn(k -> k
            .field("bbsArticleVector")
            .queryVector(queryVector)
            .k(10)))
    .build();
```
### 4.5 EgovBoard

#### 4.5.1 개요
- 역할: 게시판 서비스
- 포트: 8082
- 데이터베이스: MySQL
- 템플릿 엔진: Thymeleaf

#### 4.5.2 주요 기능

20) 게시판 관리
- 게시판 생성/수정/삭제
- 게시판 유형 관리 (일반, 공지, 익명)
- 게시판별 권한 설정

21) 게시물 관리
- CRUD 기능
- 답글 기능
- 파일 첨부
- 비밀글 지원
- 조회수 관리

22) 에디터 지원
- CKEditor5 통합
- 이미지 업로드
- HTML 태그 필터링

#### 4.5.3 주요 컴포넌트

23) 컨트롤러
```java
@Controller
@RequestMapping("/cop/brd")
public class EgovBoardController {
    // 게시판 목록
    @GetMapping("/index")
    public String index(BbsVO bbsVO, Model model)
    
    // 게시물 상세
    @PostMapping("/boardDetailView")
    public String boardDetailView(BbsVO bbsVO, Model model)
    
    // 게시물 등록
    @PostMapping("/boardInsert")
    public ResponseEntity<?> boardInsert(@ModelAttribute BbsVO bbsVO)
}
```
- 기본 경로: `/cop/brd`
- 주요 엔드포인트:
	- `GET /index`: 게시판 목록 페이지 진입점
	* `POST /boardDetailView`: 게시물 상세 조회 화면
	* `POST /boardInsert`: 게시물 등록 처리

24) 서비스
```java
@Service
public class EgovBoardServiceImpl implements EgovBoardService {
    // 공지사항 목록
    public List<BoardDTO> noticeList(BbsVO bbsVO)
    
    // 일반 게시물 목록
    public Map<String, Object> list(BbsVO bbsVO)
    
    // 게시물 등록
    public BbsVO insert(BbsVO bbsVO, List<MultipartFile> files, 
            Map<String, String> userInfo)
}
```
- 주요 메서드:
	* `noticeList()`: 공지사항 전용 목록 조회
	* `list()`: 일반 게시물 페이징 목록 조회
	* `insert()`: 파일 첨부 포함 게시물 등록
#### 4.5.4 설정

25) 웹 설정
```java
@Configuration
public class EgovBoardWeb {
    @Bean
    public SpringTemplateEngine templateEngine() {
        SpringTemplateEngine engine = new SpringTemplateEngine();
        engine.setTemplateResolver(templateResolver());
        engine.setEnableSpringELCompiler(true);
        engine.addDialect(new EgovPaginationDialect());
        return engine;
    }
}
```
- Thymeleaf 템플릿 엔진 구성
	* `SpringTemplateEngine` 빈 설정
	* Spring EL 컴파일러 활성화로 성능 최적화
	* `EgovPaginationDialect` 추가로 페이징 기능 지원

26) 필터 설정
```java
@Configuration
public class EgovBoardFilter {
    @Bean
    public FilterRegistrationBean<EgovHtmlTagFilter> egovHtmlTagFilter() {
        FilterRegistrationBean<EgovHtmlTagFilter> registrationBean = 
            new FilterRegistrationBean<>();
        registrationBean.setFilter(new EgovHtmlTagFilter());
        registrationBean.addUrlPatterns("/*");
        registrationBean.setOrder(1);
        return registrationBean;
    }
}
```
- XSS 방지를 위한 HTML 태그 필터링
	* 모든 URL 패턴(`/*`)에 적용
	* 필터 우선순위 1순위 지정
	* `EgovHtmlTagFilter` 통한 입력값 검증
#### 4.5.5 화면 구성

27) 목록 화면 (boardList.html)
```html
<table class="tbl col data">
    <thead>
        <tr>
            <th scope="col">번호</th>
            <th scope="col">제목</th>
            <th scope="col">작성자</th>
            <th scope="col">등록일</th>
            <th scope="col">조회수</th>
        </tr>
    </thead>
    <tbody id="board-list-container">
        <!-- 동적 데이터 바인딩 -->
    </tbody>
</table>
```

28) 에디터 설정 (boardInsert.html)
```javascript
ClassicEditor
    .create(document.getElementById('editor'), EditorConfig)
    .then(editor => {
        document.getElementById("insertBtn")
            .addEventListener("click", function () {
            nttCn.value = editor.getData();
            boardCreate();
        });
    });
```

#### 4.5.6 다국어 지원

29) 메시지 설정 (message_en.properties)
```properties
comCopBbs.boardMasterVO.title=Board Master Management
comCopBbs.boardMasterVO.list.bbsNm=Board Title
comCopBbs.boardMasterVO.list.bbsIntrcn=Board Explanation
```

#### 4.5.7 ID 생성 전략

30) ID 생성기 설정
```java
@Configuration
public class EgovBoardIdGeneration {
    @Bean(name="bbsMstrStrategy")
    public EgovIdGnrStrategyImpl bbsMstrStrategy() {
        EgovIdGnrStrategyImpl strategy = new EgovIdGnrStrategyImpl();
        strategy.setPrefix("BBSMSTR_");
        strategy.setCipers(12);
        strategy.setFillChar('0');
        return strategy;
    }
}
```

#### 4.5.8 운영 관리

31) 상태 확인
```java
@PostMapping("/actuator/health-info")
public ResponseEntity<String> postStatus() {
    return ResponseEntity.ok(String.format(
        "POST EgovBoard Service on\n" +
        "port: %s\n" +
        "message: %s",
        env.getProperty("local.server.port"),
        env.getProperty("egov.message")
    ));
}
```

32) 로깅
```java
private final Logger logger = 
    LoggerFactory.getLogger(EgovBoardController.class);
```

### 4.6 EgovAuthor

#### 4.6.1 개요
- 역할: 권한 관리 서비스
- 포트: 8081
- 주요기능: 권한관리, 권한그룹관리, 권한-롤 매핑

#### 4.6.2 주요 기능

33) 권한 관리 (RAM - Role Access Management)
- 권한 생성/수정/삭제/조회
- 권한-롤 매핑 관리
- 권한 검증

34) 권한그룹 관리 (RGM - Role Group Management)
- 권한그룹 CRUD
- 사용자-권한그룹 매핑
- 그룹별 권한 설정

#### 4.6.3 주요 컴포넌트

35) 권한 관리 컨트롤러
```java
@RestController
@RequestMapping("/sec/ram")
public class EgovAuthorManageController {
    @GetMapping("/list")
    public ResponseEntity<Page<AuthorInfoVO>> list(
        @ModelAttribute AuthorInfoVO authorInfoVO)
    
    @PostMapping("/insert")
    public ResponseEntity<AuthorInfoVO> insert(
        @ModelAttribute AuthorInfoVO authorInfoVO)
    
    @PutMapping("/update")
    public ResponseEntity<AuthorInfoVO> update(
        @ModelAttribute AuthorInfoVO authorInfoVO)
}
```
- 기본 경로: `/sec/ram`
- REST API 엔드포인트:
	* `GET /list`: 권한 목록 조회 (페이징 지원)
	* `POST /insert`: 신규 권한 등록
	* `PUT /update`: 기존 권한 정보 수정

36) 권한그룹 서비스
```java
@Service
public class EgovAuthorGroupServiceImpl implements EgovAuthorGroupService {
    public Page<AuthorGroupDTO> list(AuthorGroupVO authorGroupVO)
    
    public List<AuthorInfoVO> authorInfoList()
    
    public AuthorGroupVO insert(AuthorGroupVO authorGroupVO)
}
```
- 핵심 비즈니스 로직:
	* `list()`: 권한그룹 페이징 목록 조회
	* `authorInfoList()`: 전체 권한 정보 조회
	* `insert()`: 권한그룹 신규 등록
#### 4.6.4 엔티티 구조

37) 권한 정보 (AuthorInfo)
```java
@Entity
@Table(name="COMTNAUTHORINFO")
public class AuthorInfo {
    @Id
    @Column(name="AUTHOR_CODE")
    private String authorCode;
    
    @Column(name="AUTHOR_NM")
    private String authorNm;
    
    @Column(name="AUTHOR_DC")
    private String authorDc;
    
    @Column(name="AUTHOR_CREAT_DE")
    private String authorCreatDe;
}
```

38) 권한그룹 정보 (AuthorGroupInfo)
```java
@Entity
@Table(name="COMTNAUTHORGROUPINFO")
public class AuthorGroupInfo {
    @Id
    @Column(name="GROUP_ID")
    private String groupId;
    
    @Column(name="GROUP_NM")
    private String groupNm;
    
    @Column(name="GROUP_CREAT_DE")
    private String groupCreatDe;
}
```

#### 4.6.5 설정

39) ID 생성 전략
```java
@Configuration
public class EgovAuthorIdGeneration {
    @Bean(name="groupIdStrategy")
    public EgovIdGnrStrategyImpl groupIdStrategy() {
        EgovIdGnrStrategyImpl strategy = new EgovIdGnrStrategyImpl();
        strategy.setPrefix("GROUP_");
        strategy.setCipers(14);
        strategy.setFillChar('0');
        return strategy;
    }
    
    @Bean(name="roleIdStrategy")
    public EgovIdGnrStrategyImpl roleIdStrategy() {
        EgovIdGnrStrategyImpl strategy = new EgovIdGnrStrategyImpl();
        strategy.setPrefix("");
        strategy.setCipers(6);
        strategy.setFillChar('0');
        return strategy;
    }
}
```

40) 메시지 설정
```java
@Configuration
public class EgovAuthorCommon {
    @Bean
    public ReloadableResourceBundleMessageSource messageSource() {
        ReloadableResourceBundleMessageSource source = 
            new ReloadableResourceBundleMessageSource();
        source.setBasenames(
            "classpath:/messages/egovframework/com/message-common",
            "classpath:/messages/egovframework/com/sec/ram/message",
            "classpath:/messages/egovframework/com/sec/rgm/message"
        );
        source.setDefaultEncoding("UTF-8");
        source.setCacheSeconds(60);
        return source;
    }
}
```

### 4.7 EgovMobileId

#### 4.7.1 개요
- 역할: 모바일 신분증 검증 서비스
- 포트: 8085
- 주요기능: QR코드 생성, 신분증 검증, 거래내역 관리

#### 4.7.2 주요 기능

41) 모바일 신분증 검증
- 운전면허증
- 국가보훈등록증
- 재외국민 신원확인증

42) 검증 방식
- QR 코드 스캔 방식
- App to App 방식
- 푸시 알림 방식

#### 4.7.3 주요 컴포넌트

43) App to App 서비스
```java
@Service
public class App2AppServiceImpl implements App2AppService {
    private final DirectService directService;
    
    public App2AppServiceImpl(DirectService directService) {
        this.directService = directService;
    }
    
    @Override
    public T530VO start(T530VO t530) throws SpException {
        String mode = t530.getMode();
        String svcCode = t530.getSvcCode();
        
        M200VO m200 = directService.getM200(mode, svcCode, true);
        t530.setM200Base64(Base64Util.encode(ConfigBean.gson.toJson(m200)));
        
        return t530;
    }
}
```
- 역할: 모바일 앱 간 직접 통신 서비스 처리
- 주요 기능:
	* `start()`: App to App 검증 프로세스 시작
	* 모드와 서비스 코드 기반으로 M200 메시지 생성
	* Base64 인코딩된 메시지를 T530VO에 포함하여 반환
- 의존성:
	* DirectService: 직접 검증 관련 기능 제공
 
44) 웹 서비스
```java
@Service
public class WebServiceImpl implements WebService {
    private final ConfigBean configBean;
    private final DirectService directService;
    
    public M200VO getM200(TrxInfoVO trxInfo) throws SpException {
        String spServerDomain = configBean.getVerifyConfig().getSp().getServerDomain();
        String spBiImageUrl = configBean.getVerifyConfig().getSp().getBiImageUrl();
        Boolean isCi = configBean.getVerifyConfig().getSp().getIsCi();
        Boolean isTelno = configBean.getVerifyConfig().getSp().getIsTelno();
        
        String trxcode = Generator.genTrxcode();
        String mode = trxInfo.getMode();
        
        M200VO m200 = new M200VO();
        m200.setTrxcode(trxcode);
        m200.setMode(mode);
        m200.setImage(spBiImageUrl);
        m200.setCi(isCi);
        m200.setTelno(isTelno);
        m200.setHost(spServerDomain);
        
        return m200;
    }
}
```
- 역할: 웹 기반 신분증 검증 서비스 처리
- 주요 기능:
	* `getM200()`: 검증 요청 메시지(M200) 생성
	* 서버 도메인, 이미지 URL, CI/전화번호 포함 여부 설정
	* 거래코드(trxcode) 자동 생성
- 설정 관리:
	* ConfigBean을 통한 서버 설정 값 관리
	* SP(Service Provider) 관련 설정 처리
#### 4.7.4 설정

45) 애플리케이션 설정 (application.yml)
```yaml
server:
  port: 9991

spring:
  application:
    name: EgovMobileId
  main:
    allow-bean-definition-overriding: true
  config:
    import: optional:configserver:http://localhost:8888
  profiles:
    active: local

app:
  verify-file-path: ./EgovMobileId/config/verifyConfig.json

logging:
  level:
    egovframework:
      com: debug
```

46) 다국어 메시지 설정
- 영문 (message_en.properties):
```properties
mobileId.title.main=MobileId Test Screen
mobileId.driver=Driver's License
mobileId.honor=Patriots and Veterans
mobileId.expat=Overseas Korean
```

- 한글 (message_ko.properties):
```properties
mobileId.title.main=모바일 신분증 테스트 화면
mobileId.driver=운전면허증
mobileId.honor=국가보훈등록증
mobileId.expat=재외국민 신원확인증
```

#### 4.7.5 의존성

47) Omnione SDK 의존성
```xml
<dependency>
    <groupId>com.raonsecure.omnione</groupId>
    <artifactId>OmniEnt-SDK-Core</artifactId>
    <version>1.0.3.18</version>
</dependency>
<dependency>
    <groupId>com.raonsecure.omnione</groupId>
    <artifactId>OmniEnt-SDK-ServerCore</artifactId>
    <version>1.0.3.22</version>
</dependency>
<dependency>
    <groupId>com.raonsecure.omnione</groupId>
    <artifactId>OmniEnt-SDK-Verifier</artifactId>
    <version>1.0.3.21</version>
</dependency>
```

#### 4.7.6 컨테이너화

48) Dockerfile
```dockerfile
FROM openjdk:8-jre-slim
WORKDIR /app

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY target/*.jar /app/app.jar

ENV SERVER_PORT=8086 \
    SPRING_APPLICATION_NAME=EgovMobileId \
    SPRING_PROFILES_ACTIVE=docker

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8086/actuator/health || exit 1

EXPOSE 8086

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

#### 4.7.7 프론트엔드 통합

49) QR 코드 생성
```javascript
QRCode.prototype.makeCode = function (sText) {
    this._oQRCode = new QRCodeModel(_getTypeNumber(sText, 
        this._htOption.correctLevel), 
        this._htOption.correctLevel);
    this._oQRCode.addData(sText);
    this._oQRCode.make();
    this._el.title = sText;
    this._oDrawing.draw(this._oQRCode);            
    this.makeImage();
};
```

50) 거래상태 표시 (HTML)
```html
<div class="def-list-wrap">
    <dl class="def-list">
        <dt th:text="#{mobileId.license.trxcode}"> : </dt>
        <dd id="trxcodeTag"></dd>
        <dt th:text="#{mobileId.license.trxStsCode}"> : </dt>
        <dd id="trxStsCodeTag"></dd>
        <dt th:text="#{mobileId.license.vpVerifyResult}"> : </dt>
        <dd id="vpVerifyResultTag"></dd>
    </dl>
</div>
```
### 4.8 EgovSearch

#### 4.8.1 개요
- 역할: OpenSearch 기반 통합 검색 서비스
- 포트: 9992
- 주요기능: 텍스트 검색, 벡터 검색, 인덱스 관리

#### 4.8.2 주요 기능

51) 검색 방식
- 텍스트 검색 (Match Query)
  * 전체 텍스트 검색
  * Nori 분석기 활용
  * Fuzziness 지원 (오타 교정)
- 벡터 검색
  * ONNX 임베딩 모델 활용
  * KNN 기반 유사도 검색

52) 인덱스 관리
- 텍스트 인덱스 생성/삭제
- 벡터 인덱스 생성/삭제
- MySQL 데이터 동기화

#### 4.8.3 주요 컴포넌트

53) 검색 컨트롤러
```java
@Controller
public class EgovBbsSearchController {
    @GetMapping(value="/")
    public String index()
    
    @PostMapping(value="/ext/ops/textSearchResultView")
    public String textSearchResultView(BoardVO boardVO, Model model)
    
    @PostMapping(value="/ext/ops/vectorSearchResultView")
    public String vectorSearchResultView(BoardVO boardVO, Model model)
}
```

54) 검색 서비스
```java
@Service
@RequiredArgsConstructor
public class EgovBbsSearchServiceImpl implements EgovBbsSearchService {
    @Value("${opensearch.text.indexname}")
    public String textIndexName;
    
    @Value("${opensearch.vector.indexname}")
    public String vectorIndexName;
    
    @Override
    public Page<BoardVO> textSearch(BoardVO boardVO) {
        // 텍스트 기반 검색 구현
    }
    
    @Override
    public Page<BoardVectorVO> vectorSearch(BoardVO boardVO) {
        // 벡터 기반 검색 구현
    }
}
```

55) OpenSearch API 컨트롤러
```java
@RestController
@RequestMapping("/ext/ops")
public class EgovOpenSearchAPIController {
    @GetMapping("/createTextIndex")
    public ResponseEntity<?> createTextIndex()
    
    @GetMapping("/createVectorIndex")
    public ResponseEntity<?> createVectorIndex()
    
    @GetMapping("/insertTextData")
    public ResponseEntity<?> insertTextData()
}
```

#### 4.8.4 설정

56) 애플리케이션 설정 (application.yml)
```yml
opensearch:
  protocol: https
  url: localhost
  port: 9200
  username: admin
  password: egovFrame123!@#
  keystore:
    path: ${OPENSEARCH_KEYSTORE_PATH}
    password: changeit
  text:
    indexname: text-bbs-index
  vector:
    indexname: vector-bbs-index

index:
  batch:
    size: 1000

egov:
  textsearch:
    count: 10
    page:
      size: 5
  vectorsearch:
    count: 5
    page:
      size: 5
```

57) Swagger 설정
```java
@Configuration
public class EgovSearchSwagger {
    @Bean
    public OpenAPI api() {
        Info info = new Info()
                .title("Open Search 연동 API Document")
                .version("v0.0.1")
                .description("Open Search - Spring Boot 연동의 API 명세서입니다.");

        return new OpenAPI()
                .components(new Components())
                .info(info);
    }
}
```

#### 4.8.5 검색 프로세스

58) 텍스트 검색
- Nori 분석기를 통한 형태소 분석
- Match Query 실행
- 결과 페이징 처리

59) 벡터 검색
- ONNX 모델을 통한 텍스트 임베딩
- KNN 검색 실행
- 유사도 기반 결과 정렬

#### 4.8.8 보안 설정

- OpenSearch 접근 인증
- 패스워드 환경변수 설정
- HTTPS 통신
### 4.9 EgovQuestionnaire
### 4.10 EgovCmmnCode


## 5. 보안 설정
   - SSL/TLS 구성
   - 인증/인가
   - 시크릿 관리

## 6. 부록
   - 환경변수 목록
   - 포트 구성
   - 참조 문서

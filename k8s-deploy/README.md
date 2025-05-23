# Kubernetes 배포 환경 구축

이 프로젝트는 전자정부 표준프레임워크의 공통컴포넌트 26종을 Kubernetes 환경에서 배포하기 위한 가이드입니다.

## 디렉토리 구조

```
k8s-deploy/
├── README.md              # 가이드 문서
├── bin/                   # 실행 가능한 바이너리 및 도구 디렉토리
│   └── istio-1.25.0/       # Istio 설치 용도 디렉토리
├── data/                  # 영구 데이터 저장소 디렉토리
│   ├── mysql/              # MySQL 데이터 디렉토리
│   └── opensearch/         # OpenSearch 데이터 디렉토리
│       └── nodes/          # OpenSearch 노드 데이터 디렉토리
├── manifests/             # Kubernetes 리소스 매니페스트 디렉토리
│   ├── egov-common/           # 공통 환경 변수 설정 매니페스트
│   │   ├── egov-common-configmap.yaml       # 공통 환경 변수 설정 파일
│   │   ├── egov-global-configmap.yaml       # 전역 환경 변수 설정 파일
│   ├── egov-app/           # 애플리케이션 서비스 매니페스트
│   │   ├── egov-author-deployment.yaml       # EgovAuthor 배포 파일
│   │   ├── egov-board-deployment.yaml       # EgovBoard 배포 파일
│   │   ├── egov-cmmncode-deployment.yaml    # EgovCmmnCode 배포 파일
│   │   ├── egov-login-deployment.yaml       # EgovLogin 배포 파일
│   │   ├── egov-main-deployment.yaml        # EgovMain 배포 파일
│   │   ├── egov-mobileid-pv.yaml            # EgovMobileId PV 설정 파일
│   │   ├── egov-questionnaire-deployment.yaml  # EgovQuestionnaire 배포 파일
│   │   ├── egov-search-pv.yaml              # EgovSearch PV 설정 파일
│   │   ├── egov-search-deployment.yaml      # EgovSearch 배포 파일
│   │   ├── egov-hello-deployment.yaml      # EgovHello 배포 파일: 애플리케이션 로그 (INFO) OpenTelemetry Collector로 전송
│   │   ├── egov-hello-error-deployment.yaml  # EgovHello Error 배포 파일: 애플리케이션 로그 (ERROR) OpenTelemetry Collector로 전송, Circuit Breaker 테스트용
│   │   ├── virtual-services.yaml           # VirtualService 설정 파일: 로드밸런싱 테스트용
│   │   └── destination-rules.yaml          # DestinationRule 설정 파일: Circuit Breaker 테스트용
│   ├── egov-db/            # 데이터베이스 관련 매니페스트
│   │   ├── mysql-pv.yaml                  # MySQL PV 설정 파일
│   │   ├── mysql-secret.yaml              # MySQL 비밀번호 설정 파일
│   │   ├── mysql-statefulset.yaml         # MySQL StatefulSet 설정 파일
│   │   ├── mysql-service.yaml             # MySQL 서비스 설정 파일
│   │   ├── opensearch-service.yaml        # OpenSearch 서비스 설정 파일
│   │   ├── opensearch-statefulset.yaml   # OpenSearch StatefulSet 설정 파일
│   │   ├── opensearch-configmap.yaml      # OpenSearch 설정 파일
│   │   ├── opensearch-secret.yaml        # OpenSearch 비밀번호 설정 파일
│   │   ├── opensearch-certs-secret.yaml  # OpenSearch 인증서 설정 파일
│   │   ├── opensearch-dashboard-deployment.yaml  # OpenSearch Dashboard 배포 파일
│   │   └── opensearch-pv.yaml             # OpenSearch PV 설정 파일
│   ├── egov-infra/         # 인프라 서비스 매니페스트
│   │   ├── gatewayserver-deployment.yaml  # 게이트웨이 서버 배포 파일
│   │   ├── rabbitmq-service.yaml          # RabbitMQ 서비스 배포 파일
│   │   ├── rabbitmq-configmap.yaml        # RabbitMQ 환경 변수 설정 파일
│   │   ├── rabbitmq-pv.yaml               # RabbitMQ PV 설정 파일
│   │   └── rabbitmq-deployment.yaml       # RabbitMQ 배포 파일
│   ├── egov-istio/         # Istio 설치 매니페스트
│   │   ├── config.yaml       # Istio 설정 파일
│   │   └── telemetry.yaml    # Istio Telemetry 설정 파일
│   └── egov-monitoring/    # 모니터링 도구 매니페스트
│       ├── grafana.yaml      # Grafana 설정 파일
│       ├── jaeger.yaml       # Jaeger 설정 파일
│       ├── kiali.yaml        # Kiali 설정 파일
│       ├── loki.yaml         # Loki 설정 파일
│       ├── prometheus.yaml   # Prometheus 설정 파일
│       ├── alertmanager.yaml  # AlertManager 설정 파일
│       ├── alertmanager-config.yaml  # AlertManager 구성 설정 파일
│       ├── circuit-breaker-alerts-configmap.yaml  # Circuit Breaker 알림 설정 파일
│       └── opentelemetry-collector.yaml  # OpenTelemetry Collector 설정 파일
└── scripts/
    ├── setup/             # 설치 스크립트
    │   ├── setup.sh          # 전체 설치 스크립트
    │   ├── 01-setup-istio.sh         # Istio 설치 스크립트
    │   ├── 02-setup-namespaces.sh    # 네임스페이스 설정 스크립트
    │   ├── 03-setup-monitoring.sh    # 모니터링 도구 설치 스크립트
    │   ├── 04-setup-mysql.sh         # MySQL 설치 스크립트
    │   ├── 05-setup-opensearch.sh    # OpenSearch 설치 스크립트
    │   ├── 06-setup-infrastructure.sh # 인프라 서비스 설치 스크립트
    │   ├── 07-setup-applications.sh  # 애플리케이션 서비스 배포 스크립트
    │   ├── 08-setup-cicd.sh  # CICD 서비스 설치 스크립트
    │   ├── 09-show-access-info.sh  # 서비스 접근 정보 출력 스크립트
    │   └── manual-install-guide.md  # 수동 설치 가이드 스크립트
    ├── cleanup/           # 정리 스크립트
    │   ├── cleanup.sh        # 전체 정리 스크립트
    │   ├── 01-cleanup-applications.sh    # 애플리케이션 정리 스크립트
    │   ├── 02-cleanup-infrastructure.sh  # 인프라 정리 스크립트
    │   ├── 03-cleanup-mysql.sh         # MySQL 정리 스크립트
    │   ├── 04-cleanup-opensearch.sh    # OpenSearch 정리 스크립트
    │   ├── 05-cleanup-monitoring.sh    # 모니터링 도구 정리 스크립트
    │   ├── 06-cleanup-namespaces.sh    # 네임스페이스 정리 스크립트
    │   ├── 07-cleanup-istio.sh         # Istio 정리 스크립트
    │   └── 08-cleanup-cicd.sh          # CICD 정리 스크립트
    └── utils/           # 유틸리티 스크립트
        ├── test-istio/               # Istio 테스트 스크립트
        │   ├── 1-test-loadbalancing.sh  # 로드밸런싱 테스트 스크립트
        │   ├── 2-test-circuitbreaking.sh  # 서킷브레이커 테스트 스크립트
        │   ├── 3-test-alerting.sh  # 알림 전송 테스트 스크립트
        │   ├── 4-test-alert-notification.sh  # Circuit Breaker 알림 테스트 스크립트
        │   ├── 5-test-mirroring.sh  # Mirroring 테스트 스크립트
        │   ├── 6-test-fault-injection.sh  # Fault Injection 테스트 스크립트
        │   ├── 7-test-canary-release.sh  # Canary Release 테스트 스크립트
        │   ├── 8-test-blue-green-release.sh  # Blue-Green 배포 테스트 스크립트
        │   └── manual-test-istio-guide.md  # Istio 수동 테스트 가이드 스크립트
        └── pod/               # Pod 관련 유틸리티 스크립트
           ├── check-pod.sh      # Pod 상태 확인 스크립트
           ├── exec-pod.sh       # Pod 내 컨테이너 실행 스크립트
           └── logs-pod.sh       # Pod 로그 확인 스크립트

```

### 디렉토리 설명

- `bin/`: Kubernetes 클러스터에 istio를 설치하기 위한 Istio 바이너리와 클러스터 관리에 필요한 실행 파일들이 위치합니다.
  - `istioctl`: 서비스 메시 Istio를 관리하기 위한 명령줄 도구
  - `kubectl`: Kubernetes 클러스터를 관리하기 위한 명령줄 도구

- `data/`: 컨테이너의 영구 데이터를 저장하는 디렉토리입니다.
  - `mysql/`: MySQL 데이터베이스의 데이터 파일이 저장됩니다.
  - `opensearch/`: OpenSearch의 데이터와 설정 파일이 저장됩니다.
    - `nodes/`: OpenSearch 노드의 데이터 파일이 저장됩니다.
  - `rabbitmq/`: RabbitMQ의 데이터 파일이 저장됩니다.
  - `jenkins/`: Jenkins의 데이터 파일이 저장됩니다.
  - `gitlab/`: GitLab의 데이터 파일이 저장됩니다.
  - `sonarqube/`: SonarQube의 데이터 파일이 저장됩니다.
  - `nexus/`: Nexus의 데이터 파일이 저장됩니다.

- `manifests/`: Kubernetes 리소스를 정의하는 YAML 파일들이 위치합니다.
  - `egov-app/`: 전자정부 프레임워크 애플리케이션 배포 정의
  - `egov-db/`: 데이터베이스 관련 배포 정의
  - `egov-infra/`: 인프라 서비스 배포 정의
  - `egov-istio/`: Istio 설치 매니페스트
  - `egov-monitoring/`: 모니터링 도구 배포 정의
  - `egov-cicd/`: CICD 서비스 배포 정의

- `scripts/`: 설치 및 정리 스크립트들이 위치합니다.
  - `setup/`: Istio 설치부터 애플리케이션 배포까지의 설치 스크립트
  - `cleanup/`: 리소스 정리 스크립트

## Kubernetes 배포 가이드

### 1. 사전 준비사항

- Docker Desktop 설치 및 Kubernetes 활성화
- kubectl 설치
- 필요한 도구 설치 확인:
  ```bash
  kubectl version
  docker version
  ```

### 2. 프로젝트 빌드

1. 전체 서비스 빌드

- 전체 서비스 (EgovAuthor, EgovBoard, EgovCmmnCode, EgovLogin, EgovMain, EgovMobileId, EgovQuestionnaire, EgovSearch) 빌드 후 각 서비스의 `target` 폴더에 jar 파일이 생성되었는지 확인
```bash
./build.sh
```

2. 특정 서비스만 빌드하는 경우

- 특정 서비스 (EgovMain, EgovBoard) 서비스만 빌드 후 각 서비스의 `target` 폴더에 jar 파일이 생성되었는지 확인
```bash
./build.sh EgovMain
./build.sh EgovBoard
```

3. 빌드 결과 확인
- 각 서비스의 `target` 폴더에 jar 파일이 생성되었는지 확인

### 3. Docker 이미지 빌드

1. OpenSearch 이미지 빌드 (OpenSearch 이미지에 Nori 플러그인 추가)
```bash
cd EgovSearch/docker-compose/Opensearch
docker build -t opensearch-with-nori:2.15.0 -f Dockerfile .
```

2. 전체 서비스 이미지 빌드 (k8s 태그로 빌드)

- 전체 서비스 (EgovAuthor, EgovBoard, EgovCmmnCode, EgovLogin, EgovMain, EgovMobileId, EgovQuestionnaire, EgovSearch) 이미지 빌드
- 각 서비스의 `target` 폴더의 jar 파일을 기반으로 이미지 생성
- 각 서비스의 `Dockerfile.k8s`를 사용하여 `k8s` 태그로 빌드
```bash
./docker-build.sh -k
```

3. 특정 서비스만 빌드하는 경우 (k8s 태그로 빌드)

- 특정 서비스 (EgovMain, EgovBoard) 이미지 빌드
- 각 서비스의 `target` 폴더의 jar 파일을 기반으로 이미지 생성
- 각 서비스의 `Dockerfile.k8s`를 사용하여 `k8s` 태그로 빌드
```bash
./docker-build.sh -k EgovMain
./docker-build.sh -k EgovBoard
```

4. 이미지 생성 확인
```bash
docker images --format "{{.Repository}} {{.Tag}}" | grep " k8s$"  # k8s 태그로 빌드된 이미지만 조회
```

### 4. Kubernetes 배포

1. PersistentVolume 설정 확인 및 수정
각 PV의 hostPath를 로컬 환경에 맞게 수정해야 합니다:

a. MySQL PV 설정 (`k8s-deploy/manifests/egov-db/mysql-pv.yaml`):
```yaml
spec:
  hostPath:
    path: "/your/local/path/k8s-deploy/data/mysql"  # 로컬 절대 경로로 수정
```

b. OpenSearch PV 설정 (`k8s-deploy/manifests/egov-db/opensearch-pv.yaml`):
```yaml
spec:
  hostPath:
    path: "/your/local/path/k8s-deploy/data/opensearch"  # 로컬 절대 경로로 수정
```

c. RabbitMQ PV 설정 (`k8s-deploy/manifests/egov-infra/rabbitmq-pv.yaml`):
```yaml
spec:
  hostPath:
    path: "/your/local/path/k8s-deploy/data/rabbitmq"  # 로컬 절대 경로로 수정
```

d. EgovMobileId PV 설정 (`k8s-deploy/manifests/egov-app/egov-mobileid-pv.yaml`):
```yaml
spec:
  hostPath:
    path: "/your/local/path/EgovMobileId/config"  # 로컬 절대 경로로 수정
```

e. EgovSearch PV 설정 (`k8s-deploy/manifests/egov-app/egov-search-pv.yaml`):
```yaml
# Config PV
spec:
  hostPath:
    path: "/your/local/path/EgovSearch-config/config"  # 로컬 절대 경로로 수정

# Model PV
spec:
  hostPath:
    path: "/your/local/path/EgovSearch-config/model"  # 로컬 절대 경로로 수정

# Example PV
spec:
  hostPath:
    path: "/your/local/path/EgovSearch-config/example"  # 로컬 절대 경로로 수정

# Cacerts PV
spec:
  hostPath:
    path: "/your/local/path/EgovSearch-config/cacerts"  # 로컬 절대 경로로 수정
```

2. 데이터베이스 초기화 스크립트 실행
```bash
cd EgovMain/src/main/resources
./initdb.sh
```

3. 데이터베이스 초기화 확인


4. 설치 스크립트 실행
```bash
cd k8s-deploy/scripts/setup
./01-setup-istio.sh
./02-setup-namespaces.sh
./03-setup-monitoring.sh
./04-setup-mysql.sh
./05-setup-opensearch.sh
./06-setup-infrastructure.sh
./07-setup-applications.sh
```

또는 전체 설치 스크립트 실행

```bash
./setup.sh
```

설치 과정:
- Istio 서비스 메시 설치 (istio-system 네임스페이스, Istio 텔레메트리 설정)
- Namespace 생성 (egov-infra, egov-app, egov-db, egov-monitoring)
- 모니터링 도구 설치 (Prometheus, Grafana, Kiali, Jaeger, OpenTelemetry Collector)
- 데이터베이스 설치 (MySQL, OpenSearch, OpenSearch Dashboard)
- 인프라 서비스 설치 (Gateway, RabbitMQ)
- 애플리케이션 서비스 배포 (EgovMain, EgovBoard, EgovLogin, EgovAuthor, EgovMobileId, EgovQuestionnaire, EgovCmmnCode, EgovSearch)

### 5. 서비스 접근

1. Gateway 서비스 접근 정보 확인
```bash
kubectl get svc gateway-server -n egov-infra
```

2. 모니터링 도구 접근

각 모니터링 도구의 역할과 접근 URL:

- Kiali (http://localhost:30001)
  - Istio 서비스 메시 시각화 및 모니터링 도구
  - 마이크로서비스 간의 통신 흐름과 의존성 확인
  - 트래픽 흐름, 서비스 헬스 체크, 설정 검증 기능 제공

- Grafana (http://localhost:30002)
  - 데이터 시각화 및 모니터링 대시보드 제공
  - Prometheus의 메트릭을 기반으로 다양한 차트와 그래프 생성
  - 사용자 정의 대시보드 생성 및 알림 설정 가능

- Jaeger (http://localhost:30003)
  - 분산 트레이싱 시스템
  - 마이크로서비스 간의 요청 추적 및 성능 병목 지점 분석
  - 요청의 전체 처리 과정과 각 단계별 소요 시간 확인

- Prometheus (http://localhost:30004)
  - 메트릭 수집 및 저장을 담당하는 시계열 데이터베이스
  - CPU, 메모리 사용량, 요청 수, 응답 시간 등 시스템 메트릭 모니터링
  - 알림 규칙 설정 및 관리 기능 제공

기본 접속 정보:
- Grafana: admin/admin (초기 접속 시 비밀번호 변경 필요)
- Kiali: admin/admin (기본값)

3. 애플리케이션 접근 정보 확인
```bash
kubectl get svc -n egov-app
```

4. 애플리케이션 접근 URL
- EgovMain: http://localhost:9000/main/
  - 로그인 일반 계정: USER/rhdxhd12
  - 로그인 업무 계정: TEST1/rhdxhd12

### 6. Pod 관리

#### Pod 상태 확인

Pod 상태를 확인하기 위한 스크립트를 제공합니다.

```bash
./scripts/utils/pod/check-pod.sh [namespace]
```

사용 가능한 네임스페이스:
- egov-app
- egov-db
- egov-infra
- egov-monitoring
- all (모든 네임스페이스 확인)

사용 예시:
```bash
# 특정 네임스페이스의 Pod 확인
./scripts/utils/pod/check-pod.sh egov-app
./scripts/utils/pod/check-pod.sh egov-monitoring

# 모든 네임스페이스의 Pod 확인
./scripts/utils/pod/check-pod.sh all
```

제공하는 정보:
- Pod 상태 (Running, Ready)
- 재시작 횟수
- 리소스 사용량 (CPU, Memory)
- 문제가 있는 Pod의 이벤트 로그
- 모니터링 서비스 엔드포인트 정보 (egov-monitoring 네임스페이스)

#### Pod 로그 조회

애플리케이션 로그를 조회하기 위한 스크립트를 제공합니다.

```bash
./scripts/utils/pod/logs-pod.sh <application-name> [-f|--follow] [-t|--tail <lines>] [-p|--previous]
```

지원하는 애플리케이션:
- egov-main
- egov-board
- egov-login
- egov-author
- egov-mobileid
- egov-questionnaire
- egov-cmmncode
- egov-search

데이터베이스:
- mysql
- opensearch

인프라 서비스:
- gateway-server
- rabbitmq

모니터링 서비스:
- prometheus
- grafana
- kiali
- jaeger
- loki
- otel-collector

옵션:
- `-f, --follow`: 실시간으로 로그 출력을 계속 따라감
- `-t, --tail <lines>`: 마지막 몇 줄을 표시할지 지정 (기본값: 100)
- `-p, --previous`: 이전 컨테이너 인스턴스의 로그 표시

사용 예시:
```bash
# 기본 사용 (마지막 100줄 표시)
./scripts/utils/pod/logs-pod.sh egov-main

# 실시간 로그 보기
./scripts/utils/pod/logs-pod.sh egov-board -f

# 마지막 500줄 보기
./scripts/utils/pod/logs-pod.sh egov-login -t 500

# 이전 컨테이너의 로그 보기
./scripts/utils/pod/logs-pod.sh egov-search -p

# 모니터링 서비스 로그 보기
./scripts/utils/pod/logs-pod.sh prometheus
./scripts/utils/pod/logs-pod.sh grafana -f
```

#### Pod 명령어 실행

Pod 내에서 명령어를 실행하기 위한 스크립트를 제공합니다.

```bash
./scripts/utils/pod/exec-pod.sh <application-name> [-c|--container <container-name>]
```

지원하는 애플리케이션:
- egov-main
- egov-board
- egov-login
- egov-author
- egov-mobileid
- egov-questionnaire
- egov-cmmncode
- egov-search
- mysql
- opensearch
- gateway-server
- rabbitmq
- prometheus
- grafana
- kiali
- jaeger
- loki
- otel-collector

옵션:
- `-c, --container <container-name>`: 컨테이너 이름 지정 (기본값: Pod의 첫 번째 컨테이너)

사용 예시:
```bash
# 기본 사용 (첫 번째 컨테이너에서 명령어 실행)
./scripts/utils/pod/exec-pod.sh egov-main

# 특정 컨테이너에서 명령어 실행
./scripts/utils/pod/exec-pod.sh egov-board -c egov-board-container

# 모니터링 서비스에서 명령어 실행
./scripts/utils/pod/exec-pod.sh prometheus
./scripts/utils/pod/exec-pod.sh grafana -c grafana-container
```

#### Pod 문제 해결

1. 파드 상태 확인
```bash
kubectl describe pod <pod-name> -n <namespace>
```

2. 로그 확인
```bash
kubectl logs <pod-name> -n <namespace>
```

3. 파드 재시작
```bash
kubectl rollout restart deployment <deployment-name> -n <namespace>
```


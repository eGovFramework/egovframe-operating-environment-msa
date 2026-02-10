# Istio 및 OpenTelemetry 운영환경 가이드
## 표준프레임워크 MSA 공통컴포넌트 가져오기

### 레포지토리에서 가져오기
ConfigServer, GatewayServer, EurekaServer, EgovAuthor, EgovBoard, EgovCmmnCode, EgovCmmnCode, EgovCmmnCode, EgovLogin, EgovMain, EgovQuestionnaire, EgovMobileId 12종 프로젝트를 가져온다.
```
# 모든 표준프레임워크 MSA 공통컴포넌트 프로젝트를 클론하여 가져온다.
./import_msa_project.sh
```

## 1. Istio 및 OpenTelemetry 소개

- [Istio - Service Mesh 플랫폼](/doc/intro/istio.md)
- [OpenTelemetry - 관찰 가능성 프레임워크(모니터링)](/doc/intro/opentelemetry.md)

## 2. Docker 기반 배포 및 가이드

- 구성
  - [시스템 요구사항](/doc/docker/system_requirements.md)
  - [컨테이너 구성](/doc/docker/container.md)
  - [시스템 아키텍처](/doc/docker/architecture-diagram.md)

- 설치가이드
  - [Step1. 환경설정 ▷](/doc/docker/step1.md)   
  - [Step2. 프로젝트 준비 ▷](/doc/docker/step2.md)   
  - [Step3. 프로젝트 빌드 ▷](/doc/docker/step3.md)   
  - [Step4. 도커 이미지 빌드 ▷](/doc/docker/step4.md)   
  - [Step5. 서비스 실행 ▷](/doc/docker/step5.md)   

## 3. Kubernetes 기반 배포 및 가이드

- 모니터링 인프라 환경 구성

  |서비스 그룹|서비스 명|오픈소스 명|버전|라이선스|비고|
  |---|---|---|---|---|---|
  |Cloud Native|Container Orchestration|Kubernetes|1.32.5|Apache 2.0||
  |Cloud Native|Service Mesh|Istio|1.26.2|Apache 2.0||
  |Monitoring|Telemetry Pipeline|OpenTelemetry Collector|0.120.0|Apache 2.0||
  |Monitoring|Metrics & Alerting|Prometheus|2.53.0|Apache 2.0|TimeSeries DB|
  |Monitoring|Log Storage|Loki|3.2.2|AGPL-3.0||
  |Monitoring|Distributed Tracing|Jaeger|1.63.0|Apache 2.0||
  |Monitoring|Distributed Tracing|Tempo|2.6.0|AGPL-3.0||
  |Monitoring|Dashboard & Visualization|Grafana|11.3.1|AGPL-3.0||
  |Monitoring|Traffic Visualization|Kiali|2.11.0|Apache 2.0||
  |Monitoring|Alert Management|AlertManager|0.25.0|Apache 2.0||

- 배포 가이드
  - [Step1. Namespace 생성 ▷](/doc/kubernetes/namespace.md)
  - [Step2. Istio 배포 ▷](/doc/kubernetes/istio.md)
  - [Step3. NFS Provisioner 배포 ▷](/doc/kubernetes/nfs.md)
  - [Step4. 모니터링 도구 배포 ▷](/doc/kubernetes/monitoring.md)
  - [Step5. DB 구성 및 배포 ▷](/doc/kubernetes/db.md)
  - [Step6. Infra 구성 및 배포 ▷](/doc/kubernetes/infra.md)
  - [Step7. Application 구성 및 배포 ▷](/doc/kubernetes/app.md)
  

## 4. Istio 구성 및 설정 가이드
- [Service Mesh 설정 및 관리](/doc/istio/istio_config_guide.md)
- [Istio 트래픽 정책](/doc/istio/istio_traffic_policy.md)
- [Istio Alert Manager](/doc/istio/istio_alert_manager.md)

## 5. OpenTelemetry 구성 및 설정 가이드
- [관찰 가능성 설정 및 구현](/doc/opentelemetry/opentelemetry_config_guide.md)
- [대시보드 활용 가이드](/doc/opentelemetry/monitoring_ui.md)


# 로컬 개발 환경 구축

## 빌드 전 설정

### ConfigServer 설정
- `ConfigServer/src/main/resources/application.yml` 에서 search-locations를 실제 설정 저장소 경로로 변경

### EgovMobileId 설정
다음 파일들의 존재 여부 및 내용을 확인:
- `verifyConfig.json`
- `sp.wallet`
- `sp.did`

### EgovSearch 설정
- `EgovSearch/src/main/resources/application.yml` 에서 다음 항목을 실제 사용할 값으로 변경
  - opensearch.password: yourStrongPassword123!
  - opensearch.keystore.path: /Library/Java/JavaVirtualMachines/jdk-17.0.1.jdk/Contents/Home/lib/security/cacerts
  - opensearch.keystore.password: changeit
  - app.search-config-path: ./searchConfig.json

## 쉘 스크립트

- 실행권한 확인

```
chmod +x *.sh
```

- 쉘 스크립트 사용방법

```
./build.sh # 모든 서비스 빌드
./build.sh EgovMobileId # 특정 서비스만 빌드
./start.sh # 모든 서비스 시작
./start.sh EgovMobileId # 특정 서비스만 시작
./stop.sh # 모든 서비스 중지
./stop.sh EgovMobileId # 특정 서비스만 중지
./status.sh # 모든 서비스 상태 확인

./rebuild.sh # 모든 서비스 재빌드 (중지, 빌드, 시작)
./rebuild.sh EgovMobileId # 특정 서비스만 재빌드 (중지, 빌드, 시작)
```

# 배포 환경 구축

## Docker 배포
Docker를 사용한 배포 방법은 [docker-deploy/README.md](docker-deploy/README.md)를 참조하세요.

## Kubernetes 배포
Kubernetes를 사용한 배포 방법은 [k8s-deploy/README.md](k8s-deploy/README.md)를 참조하세요.

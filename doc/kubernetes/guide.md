# 쿠버네티스 배포

## 환경
### 1. 버전
|시스템|버전|기준적용일
|---|---|---|
|kubernetes|1.32.5|2025/7/10|
|Istio|1.25.3|2025/7/10|
|OpenTelemetry|0.120.0|2025/7/10|


### 2. 환경설정

#### 1) Docker Desktop 설치
#### 2) Project Clone
#### 3) Project Import

※ Docker Desktop 설치 ~ Project Import 방법은 아래의 가이드와 동일합니다.

#### 4) Kubernetes 활성화

## 배포 가이드

### 1. 네임스페이스 생성
```bash
kubectl create namespace egov-app
kubectl create namespace egov-db
kubectl create namespace egov-infra
kubectl create namespace egov-monitoring
kubectl create namespace egov-storage
```

### 2. ConfigMap 설치
#### 1) egov-common-configmap.yaml
- 사용하는 IP로 수정   
    `APIGATEWAY_ALLOWED_ORIGIN: http://localhost:9000,http://<서버의 IP>:9000`   
    *','로 구분하여 여러개 지정 가능
#### 2) configmap 배포
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/common/egov-common-configmap.yaml -n egov-app
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/common/egov-common-configmap.yaml -n egov-infra
```

### 3. Istio 설정
#### 1) Configmap 생성
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-istio/config.yaml
```
#### 2) Istio Injection 레이블 추가
```bash
kubectl label namespace egov-app istio-injection=enabled --overwrite
```

#### 3) 필요한 네임스페이스에 사이드카 주입 활성화
```bash
kubectl label namespace egov-infra istio-injection=enabled --overwrite
```

#### 4) Telemetry 설정 적용
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-istio/telemetry.yaml
```

### 4. NFS Provisioner 설치
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-storage/nfs-sa.yaml
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-storage/nfs-sc.yaml
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-storage/nfs-deployment.yaml
```

### 5. 모니터링 도구 설치
#### 1) Cert-Manager 설정
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
```
#### 2) OpenTelemetry Operator 설치
```bash
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml
```

#### 3) Loki pvc 생성
```bash
 kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/loki-pv-nfs.yaml
```

#### 4) AlertManager Config 설정
- `egov-monitoring/alertmanager-config.yaml`
```bash
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
      slack_api_url: 'https://hooks.slack.com/services/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'
```
- configmap 설정
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/alertmanager-config.yaml
```
- circuit-breaker 설정
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/circuit-breaker-alerts-configmap.yaml
```

#### 5) Prometheus pvc 적용
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/prometheus-pv-nfs.yaml
```

#### 6) 모니터링 도구 6종 설치
```bash
#prometheus
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/prometheus.yaml
#grafana
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/grafana.yaml
#kiali
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/kiali.yaml
#jaeger
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/jaeger.yaml
#loki
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/loki.yaml
#alertmanager
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/alertmanager.yaml
```

#### 7) OpenTelemetry Collector 설정 적용
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/opentelemetry-collector.yaml
```

### 6. DB 설치
#### 1) NFS PV 적용
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-db/mysql-pv-nfs.yaml
```
#### 2) Mysql 배포
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-db/mysql.yaml
```

#### 3) DB 데이터 초기화(mysql)
- 기존 공통컴포넌트 Script: `k8s-deploy/scripts/dbscripts/`
    - com_DDL_mysql.sql
    - com_DML_mysql.sql
    - com_Comment_mysql.sql

- MSA 전용 Script: `EgovAuthor/script
    - ddl, dml, comment

#### 4) OpenSearch 
- nfs pv 구성
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-db/opensearch-pv-nfs.yaml
```
- OpenSearch
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-db/opensearch.yaml
```
- OpenSearch Dashboards
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-db/opensearch-dashboard.yaml
```

### 7. Infra 설치 (RabbitMQ, Gateway)
#### 1) RabbitMQ
- nfs pv 구성
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-infra/rabbitmq-pv-nfs.yaml
```
- RabbitMQ 설치
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-infra/rabbitmq-configmap.yaml
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-infra/rabbitmq-deployment.yaml
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-infra/rabbitmq-service.yaml
```
#### 2) GatewayServer
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-infra/gatewayserver-deployment.yaml
```

### 8. Application 배포
#### 1) MySQL Secret 복사
```bash
kubectl get secret mysql-secret -n egov-db -o yaml | sed 's/namespace: egov-db/namespace: egov-app/' | kubectl apply -f -
```
#### 2) fileupload pv 생성
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-fileupload-pvc-nfs.yaml
```

#### 3) Application 배포
```bash
#메인 레이아웃
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-main-deployment.yaml
#게시판 (egov-board)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-board-deployment.yaml
#로그인 (egov-login)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-login-deployment.yaml
#로그인 정책 (loginPolicy)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-loginpolicy-deployment.yaml
#권한 (egov-author)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-author-deployment.yaml
#설문 (egov-questionnaire)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-questionnaire-deployment.yaml
#공통코드 (egov-cmmncode)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-cmmncode-deployment.yaml
```

#### 4) EgovSearch
*EgovSearch를 사용하는 경우 서버구성 등에 관련된 사항은 [EgovSearch 가이드](https://github.com/eGovFramework/egovframe-common-components-msa-krds/blob/main/EgovSearch/README.md) 를 참조하시기 바랍니다.



#### 5) EgovMobileId

*EgovMobileId 사용하는 경우 서버구성 등에 관련된 사항은 [EgovMobileId 가이드](https://github.com/eGovFramework/egovframe-common-components-msa-krds/blob/main/EgovMobileId/README.md) 를 참조하시기 바랍니다.

### 9. 실행 확인
#### 1) 모니터링 도구
| 서비스 | 포트 |
|---|---|
|Kiali|30001|
|Grafana|30002|
|Jaeger|30003|
|Prometheus| 30004|
|AlertManager |30004|

#### 2) Infra / DB
| 서비스 | 포트 |
|---|---|
|RabbitMQ|31672|
|OpenSearch Dashboard|30561|

#### 4) Application
| 서비스 | 포트 |기타|
|---|---|---|
|EgovSearch Swagger UI|30992|swagger-ui.html|
|EgovMain|9000|main|

http://<대표IP>:포트/기타   
ex) http://xxx.xxx.xxx.xxx:30992/swagger-ui.html

- 로그인 일반 계정: USER/rhdxhd12
- 로그인 업무 계정: TEST1/rhdxhd12
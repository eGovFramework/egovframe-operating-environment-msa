## 모니터링 도구 배포
monitoring 도구의 동작 방식

![prometheus](/images/prometheus.png)
### 1. Cert Manager 배포
TLS/SSL 인증서 발급 및 관리르 자동화 하는 도구
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
```
### 2. OpenTelemetry Operator 배포
Kubernetes환경에서 Opentelemetry를 사용한 관측 가능성(Obserbility)을 자동화하는 역할로 애플리케이션 계측, 데이터수집, 처리 및 내보내기 작업을 관리
```bash
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml
```
   - CertManager가 Running이 되지 않은 상태에서 배포하면 에러가 발생
   - `kubectl get pods -n egov-monitoring`을 통해 cert-manager배포 상태 확인 후 operator 배포
### 3. AlertManager 배포
Prometheus에서 발생한 알림을 받아 처리하고 라우팅하여 수신자에게 전송하는 도구
#### 1) configmap
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/alertmanager-config.yaml
```
#### 2) circuit-breaker

```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/circuit-breaker-alerts-configmap.yaml
```
### 4. Loki pv 생성
```bash
 kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/loki-pv-nfs.yaml
 ```
### 5. Prometheus pv 생성
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/prometheus-pv-nfs.yaml
```

### 6. 모니터링 도구 설치
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
### 7. OpenTelemetry Collector 배포
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-monitoring/opentelemetry-collector.yaml
```

### 8. 서비스 확인
#### 1) 정보수집과 모니터링 시각화 과정
![monitoring](/images/monitoring.png)

#### 2) 서비스 페이지 접속 정보
| 서비스 | 포트 |정보|
|---|---|---|
|Kiali|30001|Service Mesh 내의 매트릭스와 로그 데이터를 수집하고 시각화하는 도구 |
|Grafana|30002|데이터 시각화 도구|
|Jaeger|30003|분산추적 시스템|
|Prometheus| 30004|시스템 모니터링 및 알림 툴킷|
|AlertManager |30004|Prometheus의 알림 규칙(Alert Rules)을 바탕으로 알림을 전송하는 도구|



---
<div align="center">
   <table>
     <tr>
        <th><a href="nfs.md">◁ Step3. NFS Provisioner 배포</a></th>
        <th>Step4. 모니터링 도구 배포</th>
        <th><a href="db.md">Step5. DB 구성 및 배포 ▷</a></th>
     </tr>
   </table>
</div>
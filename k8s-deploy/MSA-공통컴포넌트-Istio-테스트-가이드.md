# MSA 공통컴포넌트 Istio 테스트 가이드

이 문서에서는 전자정부 표준프레임워크 MSA 공통컴포넌트 환경에서 Istio를 활용한 서비스 메시 기능의 테스트 방법을 안내합니다. Istio 구성 요소, 트래픽 관리, 서킷브레이커, 알림 설정 등을 순차적으로 다루며, 실제 테스트 시 사용할 예시 스크립트와 리소스도 설명합니다.

## 1. 개요

### 1.1 테스트 환경

- Kubernetes 클러스터
    
- Istio 1.25.0
    
- 샘플 애플리케이션: egov-hello (테스트용)
    

### 1.2 테스트 시나리오

1. 로드밸런싱
    
2. 서킷브레이커
    
3. 트래픽 관리 (Fault Injection, Mirroring 등)
    
4. 모니터링 및 알림 설정
    

## 2. 사전 준비

### 2.1 Istio 설치 및 실행 확인

```bash
kubectl get pods -n istio-system
```

위 명령어 실행 시, 다음과 유사한 결과가 확인되어야 합니다.

```
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-f45dd4788-2npn8   1/1     Running   0          24h
istiod-64989f484c-48r9z                1/1     Running   0          24h
```

### 2.2 테스트 스크립트 준비

```bash
cd k8s-deploy/scripts/utils/test-istio
chmod +x *.sh
```

- 테스트에 필요한 스크립트를 실행 권한으로 변경합니다.
    

## 3. 로드밸런싱 테스트

### 3.1 테스트 구성 요소

- **Gateway Service** (`manifests/istio-system/gateway-service.yaml`)
    
    - Istio Ingress Gateway를 위한 Kubernetes Service
        
    - NodePort 타입(포트 32314)으로 외부 트래픽 수용
        
    - HTTP/2 프로토콜을 위한 port 설정
        
    
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: istio-ingressgateway
      namespace: istio-system
    spec:
      type: NodePort
      selector:
        istio: ingressgateway
      ports:
        - name: http2
          port: 80
          targetPort: 8080
          nodePort: 32314
    ```
    
- **Virtual Service** (`manifests/egov-app/virtual-services.yaml`)
    
    - URI 기반 라우팅 설정(/a/b/c/hello)
        
    - Gateway와 연동
        
    
    ```yaml
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
    metadata:
      name: egov-hello
      namespace: egov-app
    spec:
      hosts:
      - "*"
      gateways:
      - istio-system/istio-ingressgateway
      http:
      - match:
        - uri:
            prefix: /a/b/c/hello
        route:
        - destination:
            host: egov-hello
            port:
              number: 80
    ```
    
- **Destination Rule** (`manifests/egov-app/destination-rules.yaml`)
    
    - 로드밸런싱 정책(ROUND_ROBIN) 및 Circuit Breaker 설정
        
    - 트래픽 정책 정의
        
    
    ```yaml
    apiVersion: networking.istio.io/v1beta1
    kind: DestinationRule
    metadata:
      name: egov-hello
      namespace: egov-app
    spec:
      host: egov-hello
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        outlierDetection:
          interval: 1s
          consecutive5xxErrors: 3
          baseEjectionTime: 30s
          maxEjectionPercent: 100
    ```
    

이 구성으로 다음을 실현합니다:

1. 외부 접속을 위한 게이트웨이 서비스
    
2. URI 기반 라우팅(egov-hello)
    
3. 라운드 로빈 로드밸런싱 및 장애 감지(Circuit Breaker)
    

### 3.2 테스트 실행

```bash
./1-test-loadbalancing.sh
```

### 3.3 테스트 확인 사항

4. Gateway Service가 정상 배포되었는지 확인
    
5. Istio Ingress Gateway의 동작 여부 확인
    
6. Virtual Service 설정 확인
    
7. egov-hello 애플리케이션 Pod 상태 확인
    
8. 트래픽 라우팅이 정상 동작하며, 요청이 여러 Pod에 분산되는지 확인
    

### 3.4 결과 분석

- **Kiali** UI에서 서비스 엔드포인트 및 로드밸런싱 확인
    
- **Jaeger** UI에서 트레이스 및 Spans 분석
    
    - 예: `net.sock.host.addr` 필드를 확인하여 요청이 분산되었는지 확인
        

## 4. 서킷브레이커 테스트

### 4.1 테스트 구성 요소

- **EgovHello Error Deployment** (`manifests/egov-app/egov-hello-error-deployment.yaml`)
    
    - Pod 내 `FORCE_ERROR: "true"` 설정으로 500 오류를 강제로 발생
        
    - 총 3개 Pod 구성 중 1개 Pod는 항상 에러 반환
        
    
    ```yaml
    spec:
      template:
        spec:
          containers:
          - name: egov-hello
            env:
            - name: FORCE_ERROR
              value: "true"
    ```
    
- **서킷브레이커가 포함된 Destination Rule** (`manifests/egov-app/destination-rules.yaml`)
    
    - Outlier Detection을 통해 특정 Pod에서 연속 5xx 오류가 일정 횟수(3회) 이상 발생하면 30초 동안 트래픽 제외
        

### 4.2 테스트 실행

```bash
./2-test-circuitbreaking.sh
```

### 4.3 Ingress Gateway 테스트 시나리오

9. Ingress Gateway (NodePort 32314) 확인
    
10. EgovHello Error Deployment 적용
    
11. Destination Rule(서킷브레이커) 적용
    
12. 에러를 발생시키는 Pod와 정상 Pod 간 요청 분배 확인
    
13. Circuit Breaker 동작 후, 일정 시간(30초) 지난 뒤 Pod가 다시 트래픽에 포함되는지 확인
    

### 4.4 Gateway Server를 통한 테스트

- **Gateway Server**가 Istio 환경 내부에서 요청을 처리할 때도 동일한 서킷브레이커 정책 적용
    
- 예: `curl -s http://localhost:9000/a/b/c/hello` 20회 반복 요청
    

```bash
# Gateway Server 엔드포인트 테스트
for i in {1..20}; do
    echo "Request $i:"
    curl -s http://localhost:9000/a/b/c/hello
    echo
    sleep 1
done
```

#### 4.4.1 모니터링 및 분석

- **Destination Rule** 상태 확인:
    
    ```bash
    kubectl get destinationrule -n egov-app egov-hello -o yaml
    ```
    
- **Envoy 설정** 확인:
    
    ```bash
    istioctl proxy-config cluster deploy/gateway-server -n egov-infra
    ```
    
- **Kiali UI**에서 Circuit Breaker 그래프 시각화
    

### 4.5 결과 확인

- **Istio Proxy 로그** (Gateway Server, egov-hello)
    
- **애플리케이션 로그** (egov-hello 컨테이너)


```bash
# Istio Proxy 로그 확인 (Gateway Server)
kubectl logs -l app=gateway-server -c istio-proxy -n egov-infra

# Istio Proxy 로그 확인 (EgovHello)
kubectl logs -l app=egov-hello -c istio-proxy -n egov-app

# 애플리케이션 로그 확인
kubectl logs -l app=egov-hello -c egov-hello -n egov-app
```


- Kiali UI에서 Istio Circuit Breaker 동작을 시각적으로 확인
    
	- **Services > egov-hello** 화면에서 모니터링 주기를 10초(Every 10s)로 설정하면, 에러율에 따라 색상이 변경
	    
	- 에러가 많을 때는 빨간색, 에러율이 낮아지면 노란색, 서킷브레이커가 활성화(Open)되면 녹색으로 표시
	    
	- 서킷브레이커가 Open된 상태에서는 문제가 있는 Pod(예: egov-hello-error)가 트래픽에서 제외되고, Closed되면 다시 트래픽에 포함되어 에러가 발생
	    
	- 운영 환경에서는 Circuit이 Open될 정도로 에러가 발생하면, 원인 분석과 조치가 필수

![[Pasted image 20250416161426.png]]

![[Pasted image 20250416161210.png]]

![[Pasted image 20250416161238.png]]
### 4.6 운영 환경 서킷브레이커 설정 가이드

#### 4.6.1 테스트 vs 운영 환경 차이

- 테스트 설정(짧은 간격, 빠른 감지)
    
- 운영 환경(복구 시간 고려, 안정성 확보)
    

```yaml
outlierDetection:
  interval: 10s
  consecutive5xxErrors: 5
  baseEjectionTime: 300s
  maxEjectionPercent: 50
  minHealthPercent: 60
```

#### 4.6.2 설정 근거 및 복구 프로세스

14. 장애 발생 시 연속 5회 5xx → 5분간 해당 Pod 트래픽 제외
    
15. 운영팀 알림 및 초기 대응(로그 분석, 조치)
    
16. 5분 후 Half-Open 상태 진입, 트래픽 점진 재할당
    

#### 4.6.3 모니터링 및 알림

- Prometheus 규칙 설정 예시
    
- AlertManager를 통한 Slack 연동
    
- 예기치 못한 오류 발생 시 빠른 대응 가능
    

## 5. 트래픽 관리

### 5.1 가중치 기반 라우팅

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: egov-hello
spec:
  hosts:
  - egov-hello
  http:
  - route:
    - destination:
        host: egov-hello
        subset: v1
      weight: 80
    - destination:
        host: egov-hello
        subset: v2
      weight: 20
```

- v1 버전에 80%, v2 버전에 20% 트래픽 분배
    

### 5.2 Fault Injection

#### 5.2.1 Delay Injection

```yaml
fault:
  delay:
    percentage:
      value: 100
    fixedDelay: 5s
```

- 모든 요청에 대해 5초 지연 발생

- 지연에 따른 시스템의 대응 능력 및 타임아웃 설정 등을 점검 가능

- 실제 운영 환경에서는 이런 장애가 자연스럽게 발생할 수 있기 때문에 미리 Timeout 장애 대응 매커니즘을 검증
    

#### 5.2.2 Abort Injection

```yaml
fault:
  abort:
    percentage:
      value: 100
    httpStatus: 500
```

- 모든 요청에 대해 500 에러 반환

- 강제로 500 오류를 발생시키는 장애 상황을 시뮬레이션
    

#### 5.2.3 혼합 설정

```yaml
fault:
  delay:
    percentage:
      value: 50
    fixedDelay: 5s
  abort:
    percentage:
      value: 50
    httpStatus: 500
```

- 50%는 5초 지연, 나머지 50%는 500 에러 발생
    
- 시스템의 지연/장애 상황 대처 능력 및 서킷브레이커, 타임아웃 설정 등을 점검 가능

- 일부 요청은 느려지고, 일부 요청은 오류가 발생하는 복합적인 장애 상황을 재현
    

### 5.3 Mirroring

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  host: egov-hello
  subsets:
  - name: v1
    labels:
      variant: normal
  - name: v2
    labels:
      variant: error
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN

---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  hosts:
  - "*"
  gateways:
  - istio-system/istio-ingressgateway
  http:
  - match:
    - uri:
        prefix: /a/b/c/hello
    route:
    - destination:
        host: egov-hello
        subset: v1
        port:
          number: 80
    mirror:
      host: egov-hello
      subset: v2
    mirrorPercentage:
      value: 100
```

- 실트래픽은 v1으로 전달, 동일 요청을 v2로 “복사” (v2에서 실제 응답은 반환하지 않음)

- `5-test-mirroring.sh`` 스크립트 실행으로 테스트 가능
    
- 무중단 테스트나 A/B 테스트 시 활용

- 주의할 사항

	- Istio Ingress Gateway 를 통해 요청을 받으면 VirtualService를 통해 라우팅
	
	- Ingress Gateway를 통하지 않고, 클러스터 내부에서 요청을 처리하는 경우, VirtualService를 통해 라우팅하지 않음
	
	- 즉, http://localhost:9000/a/b/c/hello 와 같은 Gateway Server로 요청을 보낼 경우, Mirroring이 적용되지 않음

![[Pasted image 20250416161719.png]]

### 5.4 Canary Release

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  hosts:
  - "*"
  gateways:
  - istio-system/istio-ingressgateway
  http:
  - match:
    - uri:
        prefix: /a/b/c/hello
    route:
    - destination:
        host: egov-hello
        subset: v1
        port:
          number: 80
      weight: 90
    - destination:
        host: egov-hello
        subset: v2
        port:
          number: 80
      percent: 10
```

- 90%는 v1, 10%는 v2로 트래픽 분배

- Canary Release를 통해 새로운 버전의 서비스를 점진적으로 배포 가능


## 6. 알림 테스트

### 6.1 알림 구성 요소

- **AlertManager** (`manifests/egov-monitoring/alertmanager-config.yaml`)
    
    - Slack 등 외부 알림 연동 설정
        
    - route (라우팅)

		- `group_by, group_wait, group_interval, repeat_interval`등을 통해 알림이 묶여서 보내진다.
	
		- `severity: critical` 에 해당하는 알림은 receiver 로 전달된다.

	- receivers

		- Slack 채널 `#egovalertmanager`로 alert firing, resolved 모두 메시지가 전송된다.


```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: alertmanager-config
     namespace: egov-monitoring
   stringData:
     alertmanager.yaml: |
       global:
         resolve_timeout: 5m
         slack_api_url: 'https://hooks.slack.com/triggers/YOUR_WEBHOOK_URL'

       route:
         group_by: ['alertname', 'service', 'severity']
         group_wait: 10s
         group_interval: 10s
         repeat_interval: 1h
         receiver: 'slack-notifications'
         routes:
         - match:
             severity: critical
           receiver: 'slack-notifications'
           continue: true

       receivers:
       - name: 'slack-notifications'
         slack_configs:
         - channel: '#egovalertmanager'
           send_resolved: true
           text: >-
             {{ if eq .Status "firing" }}🔥 *Alert Firing*{{ else }}✅ *Alert Resolved*{{ end }}
             {{ range .Alerts }}
             *Alert:* {{ .Annotations.summary }}
             *Description:* {{ .Annotations.description }}
             *Service:* {{ .Labels.service }}
             *Severity:* {{ .Labels.severity }}
             *Status:* {{ .Status }}
             {{ end }}
```


- **알림 규칙** (`manifests/egov-monitoring/circuit-breaker-alerts-configmap.yaml`)

	
    ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: prometheus-rules
     namespace: egov-monitoring
   data:
     circuit-breaker-alerts.yaml: |
       groups:
       - name: CircuitBreakerAlerts
         rules:
         - alert: CircuitBreakerOpen
           expr: |
             sum(increase(istio_requests_total{
               response_code=~"5.*",
               destination_service="egov-hello.egov-app.svc.cluster.local"
             }[5m])) by (destination_service) > 3
           for: 10s
           labels:
             severity: critical
             service: egov-hello
           annotations:
             summary: "Circuit Breaker Opened for egov-hello"
             description: "3회 이상의 연속 오류 발생"
	```
    
    - 5분 동안 발생한 5xx 에러 횟수가 임계값(3)을 넘고 10초 동안 이 조건이 충족되면 `severity: critical` 라벨을 붙여 알림 전송
        
- **Prometheus** (`manifests/egov-monitoring/prometheus.yaml`)
    
    - AlertManager와 연동
        
    - 알림 규칙 적용을 위한 rule_files 설정


  ```yaml
   alerting:
     alertmanagers:
     - static_configs:
       - targets:
         - alertmanager:9093
   rule_files:
   - /etc/prometheus/rules/*.yaml

   ---
   volumeMounts:
     - name: prometheus-rules
       mountPath: /etc/prometheus/rules
   volumes:
     - name: prometheus-rules
       configMap:
         name: prometheus-rules
   ```
		

### 6.2 알림 전송 테스트

```bash
./3-test-alerting.sh
```

17. AlertManager 설정 적용 및 재배포

```bash
   kubectl apply -f manifests/egov-monitoring/alertmanager-config.yaml
   kubectl rollout restart deployment alertmanager -n egov-monitoring
```    

18. AlertManager와 Prometheus 상태 확인

   ```bash
   # 로그 확인
   kubectl logs -l app=alertmanager -n egov-monitoring

   # 설정 확인
   kubectl get secret alertmanager-config -n egov-monitoring -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d

   # 포트포워딩
   kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093

   # 상태 확인
   curl -s http://localhost:9093/-/healthy
   ```
	
19. 테스트 알림 전송 (예: `curl -H "Content-Type: application/json" -d '[ ... ]' http://localhost:9093/api/v1/alerts`)

   ```bash
   curl -H "Content-Type: application/json" -d '[{
     "labels": {
       "alertname": "TestAlert",
       "service": "test-service",
       "severity": "critical"
     },
     "annotations": {
       "summary": "Test Alert",
       "description": "This is a test alert"
     }
   }]' http://localhost:9093/api/v1/alerts
   ```
    
20. AlertManager UI 및 Slack 채널에서 알림 도착 여부 확인

   ```bash
   kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093
   ```
   - URL: http://localhost:9093/#/alerts    

### 6.3 Circuit Breaker 알림 테스트

```bash
./4-test-alert-notification.sh
```

21. Circuit Breaker Alert Rule 적용
   ```bash
   kubectl apply -f manifests/egov-monitoring/circuit-breaker-alerts-configmap.yaml
   kubectl rollout restart deployment prometheus -n egov-monitoring

   # Prometheus Rules 확인
   kubectl get configmap prometheus-rules -n egov-monitoring
   
   # 규칙 내용 상세 확인
   kubectl get configmap prometheus-rules -n egov-monitoring -o yaml
   ```
    
22. 에러 트래픽 발생(예: 20회 연속 요청)
  ```bash
  # 에러 요청 생성
  for i in {1..20}; do 
    echo "Request $i:"
    curl -s http://localhost:32314/a/b/c/hello
    echo
    sleep 0.5
  done
  ```
    
23. AlertManager 로그 및 UI 확인

  ```bash
  # AlertManager 가 정상적으로 작동하는지 로그 확인
  kubectl logs -l app=alertmanager -n egov-monitoring

  # 알림 전송 상태 확인
  kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093
  http://localhost:9093/#/alerts
  ```
    
24. Slack 채널 알림 도착 확인
    

### 6.4 알림 설정 가이드

- **임계값 조정**: 운영 환경에 맞춰 에러 횟수 5회/5분, 지속 시간 10분, 심각도 critical 등으로 변경 가능
    
- **알림 포맷**: “🔥Alert Firing” / “✅Alert Resolved” 등으로 구분
    
- **문제 해결**:
    
    - Webhook URL 확인
        
    - Prometheus, AlertManager 설정 누락 여부 확인
        
    - 알림 규칙이 실제 트래픽 패턴과 맞는지 검토

		
   ```bash
   # Prometheus UI에서 확인
   http://localhost:30004

   # 알림 조건 확인
   sum(increase(istio_requests_total{
     response_code=~"5.*",
     destination_service="egov-hello.egov-app.svc.cluster.local"
   }[5m])) by (destination_service) > 3
   ```


## 7. 문제 해결

### 7.1 일반적인 문제

- **Istio Ingress Gateway 연결 실패**
    
    ```bash
    kubectl logs -l app=istio-ingressgateway -n istio-system
    ```
    
- **Virtual Service 설정 오류**
    
    ```bash
    istioctl analyze
    kubectl get virtualservice -n egov-app
    ```
    
- **Destination Rule 상태 이상**
    
    ```bash
    kubectl get destinationrule -n egov-app
    istioctl proxy-config cluster deploy/egov-hello -n egov-app
    ```
    

### 7.2 로그 분석

- **Istio Proxy 로그**
    
    ```bash
    kubectl logs <pod-name> -c istio-proxy -n egov-app
    ```
    
- **애플리케이션 컨테이너 로그**
    
    ```bash
    kubectl logs <pod-name> -c egov-hello -n egov-app
    ```
    

문제 발생 시 로그를 분석하여, 설정 오류나 네트워크, 애플리케이션 장애 등을 파악합니다.

## 8. 참고 자료

- [Istio 공식 문서](https://istio.io/latest/docs/)
    
- [Istio 트래픽 관리 개념](https://istio.io/latest/docs/concepts/traffic-management/)
    
- [Istio Circuit Breaking](https://istio.io/latest/docs/tasks/traffic-management/circuit-breaking/)
    
- [Istio Fault Injection](https://istio.io/latest/docs/tasks/traffic-management/fault-injection/)
    

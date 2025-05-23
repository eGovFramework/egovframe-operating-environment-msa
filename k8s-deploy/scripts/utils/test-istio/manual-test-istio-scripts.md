# 전자정부 표준프레임워크 MSA 공통컴포넌트 Istio 수동 테스트 스크립트

> 테스트는 **순서대로** 진행하세요.  
> 포트포워딩은 **별도 터미널**에서 실행하는 것을 권장합니다.

---

## 1. 로드밸런싱 테스트

### 1‑1 Gateway 및 라우팅 설정 적용

```bash
# Gateway 및 라우팅 설정 적용
kubectl apply -f ../../../manifests/istio-system/gateway.yaml
kubectl apply -f ../../../manifests/istio-system/gateway-service.yaml
kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml
kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml
```

### 1‑2 상태 확인

```bash
kubectl get svc istio-ingressgateway -n istio-system
kubectl get virtualservice -n egov-app
kubectl get pods -n egov-app -l app=egov-hello
```

### 1‑3 라우팅 설정 확인

```bash
istioctl proxy-config routes deploy/istio-ingressgateway -n istio-system
```

### 1‑4 내부 서비스 테스트

```bash
kubectl run -i --rm --restart=Never curl-test \
  --image=curlimages/curl -- \
  curl http://egov-hello.egov-app/a/b/c/hello
```

### 1‑5 외부 접근 테스트

```bash
# Gateway Server 직접 호출
curl -v http://localhost:9000/a/b/c/hello

# Istio Ingress Gateway(NodePort) 호출
curl -v http://localhost:32314/a/b/c/hello
```

> URL 을 여러 번 호출한 뒤 **Grafana → Explorer → Loki**(필터 `{job="EgovHello",level="INFO"}`)  
> 와 **Jaeger Trace** 의 `net.sock.host.addr` 분포로 **ROUND_ROBIN** 동작을 확인합니다.

---

## 2. 서킷 브레이커(Circuit Breaker) 테스트

### 2‑1 Deployment 배포

```bash
# 정상 버전
kubectl apply -f ../../../manifests/egov-app/egov-hello-deployment.yaml
kubectl wait --for=condition=Ready pods -l app=egov-hello -n egov-app --timeout=300s

# 오류 발생 버전(variant=error)
kubectl apply -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml
kubectl wait --for=condition=Ready pods -l 'app=egov-hello,variant=error' -n egov-app --timeout=300s
```

### 2‑2 VirtualService / DestinationRule 적용

```bash
kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml
kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml
kubectl apply -f ../../../manifests/istio-system/gateway-service.yaml
```

### 2‑3 Circuit Breaker 동작 확인

```bash
for i in {1..20}; do
  echo "Request $i:"
  curl -s http://localhost:32314/a/b/c/hello
  echo
  sleep 0.5
done
```

_5xx 오류가 일정 횟수 이상 발생하면 Circuit (Open) → 오류 Pod 제외 → 다시 정상 응답 순으로 변하는지 확인._

---

## 3. 알림(Alert) 테스트

### 3‑1 Prometheus 알림 규칙 & AlertManager 적용

```bash
# AlertManager 확인
kubectl get pods -n egov-monitoring -l app=alertmanager

# Circuit Breaker 알림 규칙 반영
kubectl apply -f ../../../manifests/egov-monitoring/circuit-breaker-alerts-configmap.yaml
kubectl rollout restart deployment prometheus -n egov-monitoring
kubectl rollout status  deployment prometheus -n egov-monitoring --timeout=300s

# AlertManager 설정 반영
kubectl apply -f ../../../manifests/egov-monitoring/alertmanager-config.yaml
kubectl apply -f ../../../manifests/egov-monitoring/alertmanager.yaml
kubectl rollout status deployment alertmanager -n egov-monitoring --timeout=300s

# 알림 설정 확인
kubectl get secret alertmanager-config -n egov-monitoring -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d
```

### 3‑2 AlertManager 포트포워딩 & 헬스체크

```bash
kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093
curl -s http://localhost:9093/-/healthy
```

### 3‑3 테스트 알림 전송

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

### 3-4 정리

```bash
pkill -f "port-forward.*alertmanager"
```

---

## 4. 알림 조건 완화 & 통지 확인

### 4‑1 DestinationRule(Circuit Breaker 완화) 예시

```bash
# 수정본 적용
kubectl apply -f - <<EOF
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
      interval: 3s           # 더 긴 간격으로 검사
      consecutive5xxErrors: 5  # 더 많은 오류 허용
      baseEjectionTime: 30s   # 짧은 ejection 시간
      maxEjectionPercent: 50  # 절반만 ejection
EOF
```

### 4-2 에러 요청 생성 (20회 3번 반복)

```bash
for i in {1..3}; do
  for i in {1..20}; do
    echo "Request $i:"
    curl -s http://localhost:32314/a/b/c/hello
    echo
    sleep 1
  done
  sleep 5
done
```

> Slack 채널 등으로 Alert가 도착하는지 확인 후, 원본 `destination-rules.yaml` 로 **복원**하세요.

### 4-3 Alert 확인

```bash
# AlertManager UI 확인
kubectl port-forward svc/alertmanager -n egov-monitoring 9093:9093
http://localhost:9093/#/alerts
```

### 4-4 정리

```bash
pkill -f "port-forward.*alertmanager"
```

---

## 5. 트래픽 미러링 테스트

### 5‑1 사전 배포/설정

```bash
kubectl apply -f ../../../manifests/istio-system/gateway.yaml
kubectl apply -f ../../../manifests/istio-system/gateway-service.yaml

# 오류 버전 배포(v2)
kubectl apply -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml
kubectl wait --for=condition=Ready pods -l 'app=egov-hello,variant=error' -n egov-app --timeout=300s
```

#### DestinationRule (v1/v2 subsets)

```bash
kubectl apply -f - <<EOF
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
  subsets:
  - name: v1
    labels:
      variant: normal
  - name: v2
    labels:
      variant: error
EOF
```

#### VirtualService (미러링 100 %)

```bash
kubectl apply -f - <<EOF
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
EOF
```

### 5‑2 미러링 요청 & 로그 비교

```bash
for i in {1..20}; do
  echo "Request $i:"
  curl -s http://localhost:32314/a/b/c/hello
  echo
  sleep 1
done

kubectl logs -l variant=normal -c egov-hello -n egov-app --tail=10
kubectl logs -l variant=error  -c egov-hello -n egov-app --tail=10
```

---

## 6. Fault Injection 테스트

### 6‑1 지연 주입(100 %, 5 초)

```bash
kubectl apply -f - <<EOF
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
    fault:
      delay:
        percentage:
          value: 100
        fixedDelay: 5s
    route:
    - destination:
        host: egov-hello
        port:
          number: 80
EOF
```

```bash
for i in {1..5}; do
  echo "Request $i:"
  curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}\n" \
       http://localhost:32314/a/b/c/hello
  sleep 1
done
```

### 6‑2 오류 주입(100 %, HTTP 500)

```bash
kubectl apply -f - <<EOF
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
    fault:
      abort:
        percentage:
          value: 100
        httpStatus: 500
    route:
    - destination:
        host: egov-hello
        port:
          number: 80
EOF
```

```bash
for i in {1..5}; do
  echo "Request $i:"
  curl -s -w "\nHTTP_CODE:%{http_code}\n" \
       http://localhost:32314/a/b/c/hello
  sleep 1
done
```

### 6‑3 혼합 장애(지연 50 % + 오류 50 %)

```bash
kubectl apply -f - <<EOF
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
    fault:
      delay:
        percentage:
          value: 50
        fixedDelay: 5s
      abort:
        percentage:
          value: 50
        httpStatus: 500
    route:
    - destination:
        host: egov-hello
        port:
          number: 80
EOF
```

```bash
for i in {1..10}; do
  echo "Request $i:"
  curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}\n" \
       http://localhost:32314/a/b/c/hello
  sleep 1
done
```

#### 원래 VirtualService 복원

```bash
kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml
```

---

## 7. Canary Release 테스트

### 7‑1 사전 설정

```bash
kubectl apply -f ../../../manifests/istio-system/gateway.yaml
kubectl apply -f ../../../manifests/istio-system/gateway-service.yaml

# v2(Canary) 배포
kubectl apply -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml
kubectl wait --for=condition=Available deployment/egov-hello-error -n egov-app --timeout=300s
```

#### DestinationRule (v1/v2)

```bash
kubectl apply -f - <<EOF
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
  subsets:
  - name: v1
    labels:
      variant: normal
  - name: v2
    labels:
      variant: error
EOF
```

#### 초기 트래픽(90 : 10)

```bash
kubectl apply -f - <<EOF
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
      weight: 10
EOF
```

```bash
for i in {1..20}; do
  echo "Request $i:"
  curl -s http://localhost:32314/a/b/c/hello
  echo
  sleep 1
done
```

#### 업데이트 트래픽(75 : 25)

```bash
kubectl apply -f - <<EOF
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
      weight: 75
    - destination:
        host: egov-hello
        subset: v2
        port:
          number: 80
      weight: 25
EOF
```

```bash
for i in {1..20}; do
  echo "Request $i:"
  curl -s http://localhost:32314/a/b/c/hello
  echo
  sleep 1
done
```

### 7‑2 Pod 로그 확인

```bash
echo 'v1 Pod Logs:'
kubectl logs -l variant=normal -c egov-hello -n egov-app --tail=10

echo 'v2 Pod Logs:'
kubectl logs -l variant=error  -c egov-hello -n egov-app --tail=10
```

### 7‑3 정리

```bash
kubectl delete -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml
kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml
kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml
```

---

## 8. Blue‑Green 배포 테스트

### 8‑1 사전 설정

```bash
kubectl apply -f ../../../manifests/istio-system/gateway.yaml
kubectl apply -f ../../../manifests/istio-system/gateway-service.yaml
```

### 8‑2 Green 배포 & DestinationRule (v1/v2) 정의

```bash
kubectl get deployment -n egov-app egov-hello -o wide   # 현재 Blue 확인
kubectl apply -f ../../../manifests/egov-app/egov-hello-error-deployment.yaml # Green 배포
kubectl wait --for=condition=Ready pods -l 'app=egov-hello' -n egov-app --timeout=300s
```

```bash
kubectl apply -f - <<EOF
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
  subsets:
  - name: blue
    labels:
      version: v1
  - name: green
    labels:
      version: v2
EOF
```

### 8‑3 트래픽 전환 (Blue → Green)

```bash
# 초기 상태 - Blue로 100% 라우팅
kubectl apply -f - <<EOF
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
        subset: blue
        port:
          number: 80
EOF
```

```bash
# Blue 버전 테스트
for i in {1..5}; do
  echo "Request $i:"
  curl -s http://localhost:32314/a/b/c/hello
  echo
  sleep 1
done
```

```bash
# Green 버전으로 전환
kubectl apply -f - <<EOF
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
        subset: green
        port:
          number: 80
EOF
```

```bash
# Green 버전 테스트
for i in {1..5}; do
  echo "Request $i:"
  curl -s http://localhost:32314/a/b/c/hello
  echo
  sleep 1
done
```

### 8‑4 Blue/Green 로그 비교

```bash
echo 'Blue Version Logs:'
kubectl logs -l version=v1 -c egov-hello -n egov-app --tail=10

echo 'Green Version Logs:'
kubectl logs -l version=v2 -c egov-hello -n egov-app --tail=10
```

### 8‑5 롤백

```bash
# 문제 발생 시 Blue 롤백 라우팅
kubectl apply -f - <<EOF
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
        subset: blue
        port:
          number: 80
EOF
```

---

## 9. 테스트 정리 & 모니터링 URL

### 9‑1 포트포워딩·임시 Deployment 종료

```bash
pkill -f "port-forward.*alertmanager"
kubectl delete deployment egov-hello-error -n egov-app
kubectl apply -f ../../../manifests/egov-app/destination-rules.yaml
kubectl apply -f ../../../manifests/egov-app/virtual-services.yaml
```

### 9‑2 대시보드

|서비스|URL|
|---|---|
|Kiali|[http://localhost:30001](http://localhost:30001/)|
|Grafana|[http://localhost:30002](http://localhost:30002/)|
|Jaeger|[http://localhost:30003](http://localhost:30003/)|
|Prometheus|[http://localhost:30004](http://localhost:30004/)|
|AlertManager (포트포워딩 필요)|[http://localhost:9093](http://localhost:9093/)|

---

> 위 단계별 명령을 그대로 실행하면 **로드밸런싱 → Circuit Breaker → Alert → Mirroring → Fault Injection → Canary → Blue‑Green** 전 과정을 재현할 수 있습니다.
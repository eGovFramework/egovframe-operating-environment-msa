# OpenTelemetry 구성 가이드

## 개요

본 프로젝트에서는 마이크로서비스의 관찰 가능성(Observability)을 위해 OpenTelemetry를 구성하고 있습니다. OpenTelemetry는 메트릭, 추적, 로그를 통합하여 수집하고 분석할 수 있는 통합 관찰성 프레임워크이다.

## 1. OpenTelemetry 아키텍처 개요

### 1.1 구성 요소
- **OpenTelemetry Operator**: Kubernetes 환경에서 자동 계측 관리
- **OpenTelemetry Collector**: 텔레메트리 데이터 수집, 처리, 전송
- **Auto-Instrumentation**: 자동 계측을 통한 Zero-Code 구현
- **Manual Instrumentation**: 애플리케이션 레벨 설정

### 1.2 데이터 플로우
```
애플리케이션 → OpenTelemetry Agent → OpenTelemetry Collector → 백엔드 시스템
                    ↓                        ↓                      ↓
               자동 계측              수집/처리/변환         Jaeger/Prometheus/Loki
```

## 2. OpenTelemetry Operator 구성

### 2.1 Operator 설치
```bash
# OpenTelemetry Operator 배포
kubectl apply -f k8s-deploy/manifests/egov-monitoring/opentelemetry-operator.yaml
```

### 2.2 Operator 확인
```bash
# Operator 상태 확인
kubectl get pods -n opentelemetry-operator-system

# CRD 확인
kubectl get crd | grep opentelemetry
```

## 3. OpenTelemetry Collector 구성

### 3.1 Collector 배포 (`k8s-deploy/manifests/egov-monitoring/opentelemetry-collector.yaml`)

```yaml
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: egov-monitoring
spec:
  mode: daemonset  # 각 노드에 하나씩 배포
  serviceAccount: otel-collector-collector
  image: otel/opentelemetry-collector-contrib:0.120.0
  
  # Istio 사이드카 주입 비활성화
  podAnnotations:
    sidecar.istio.io/inject: "false"
  
  # 환경 변수 설정
  env:
    - name: K8S_NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
```

### 3.2 볼륨 마운트 설정
```yaml
  volumeMounts:
    - name: varlogcontainers
      mountPath: /var/log/containers
    - name: varlogpods
      mountPath: /var/log/pods
    - name: varlibdockercontainers
      mountPath: /var/lib/docker/containers
  
  volumes:
    - name: varlogcontainers
      hostPath:
        path: /var/log/containers
    - name: varlogpods
      hostPath:
        path: /var/log/pods
    - name: varlibdockercontainers
      hostPath:
        path: /var/lib/docker/containers
```

### 3.3 Collector 구성 파일

#### 3.3.1 Receivers
외부 데이터를 Collector로 끌어오는 수집 역할
```yaml
config:
  receivers:
    # OpenTelemetry 프로토콜 수신
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317  # gRPC 엔드포인트
        http:
          endpoint: 0.0.0.0:4318  # HTTP 엔드포인트
    
    # 파일 로그 수신
    filelog:
      include: [ /var/log/containers/*egov*.log ]
      exclude: [ /var/log/containers/*istio*.log ]
      start_at: end
      include_file_path: true
      include_file_name: true
      operators:
        # 컨테이너 정보 추출
        - type: regex_parser
          regex: '^.*containers/(?P<pod_name>[^_]+)_(?P<namespace>[^_]+)_(?P<container>[^-]+)-.*\.log$'
          parse_from: attributes["log.file.path"]
          parse_to: attributes.container_info
        
        # JSON 로그 파싱
        - type: json_parser
          parse_to: attributes
          timestamp:
            parse_from: attributes.time
            layout: '%Y-%m-%dT%H:%M:%S.%LZ'
        
        # 로그 본문 이동
        - type: move
          from: attributes.log
          to: body
    
    # Prometheus 메트릭 수신 (Istio)
    prometheus:
      config:
        scrape_configs:
          - job_name: 'istio-proxy'
            kubernetes_sd_configs:
              - role: pod
            relabel_configs:
              - source_labels: [__meta_kubernetes_pod_container_name]
                action: keep
                regex: "istio-proxy"
              - source_labels: [__meta_kubernetes_pod_ip]
                action: replace
                regex: (.*)
                replacement: $1:15090
                target_label: __address__
```

#### 3.3.2 Processors
수집된 데이터를 “가공·필터링·집계”하는 중간 처리 역할
```yaml
  processors:
    # 배치 처리
    batch:
      timeout: 10s
      send_batch_size: 1024
    
    # 메모리 제한
    memory_limiter:
      check_interval: 5s
      limit_percentage: 80
      spike_limit_percentage: 25
    
    # 속성 처리
    attributes:
      actions:
        - key: pod
          from_attribute: container_info_pod_name
          action: insert
        - key: namespace
          from_attribute: container_info_namespace
          action: insert
        - key: container
          from_attribute: log.container.name
          action: insert
        - key: cluster
          value: "egov"
          action: insert
        - key: k8s.node.name
          from_attribute: K8S_NODE_NAME
          action: insert
```

#### 3.3.3 Exporters
가공된 데이터를 필요한 곳(Grafana, Promethus, Tempo, Loki 등)으로 보내주는 역할
```yaml
  exporters:
    # Jaeger 추적 데이터 전송
    otlp/jaeger:
      endpoint: jaeger-collector.egov-monitoring.svc.cluster.local:4317
      tls:
        insecure: true
    
    # Tempo 추적 데이터 전송
    otlp/tempo:
      endpoint: tempo.egov-monitoring.svc.cluster.local:4317
      tls:
        insecure: true
    
    # Prometheus 메트릭 전송
    prometheus:
      endpoint: 0.0.0.0:8889
      namespace: egov-monitoring
      const_labels:
        cluster: "egov"
      send_timestamps: true
      metric_expiration: 180m
      enable_open_metrics: true
    
    # Loki 로그 전송
    loki:
      endpoint: http://loki.egov-monitoring.svc.cluster.local:3100/loki/api/v1/push
      tls:
        insecure: true
```

#### 3.3.4 Service Pipelines (receivers,processors,exporters 파이프라인 정의)
```yaml
  service:
    pipelines:
      # 추적 데이터 파이프라인
      traces:
        receivers: [otlp]
        processors: [memory_limiter, batch, attributes]
        exporters: [otlp/jaeger, otlp/tempo]
      
      # 메트릭 데이터 파이프라인
      metrics:
        receivers: [otlp, prometheus]
        processors: [memory_limiter, batch]
        exporters: [prometheus]
      
      # 로그 데이터 파이프라인
      logs:
        receivers: [otlp, filelog]
        processors: [memory_limiter, batch, attributes]
        exporters: [loki]
```

### 3.4 Collector Service
애플리케이션이나 모니터링 도구가 Collector에 접근할 수 있게 하는 네트워크 게이트웨이
```yaml
apiVersion: v1
kind: Service
metadata:
  name: otel-collector
  namespace: egov-monitoring
spec:
  ports:
  - name: grpc-otlp
    port: 4317        # gRPC OTLP
    protocol: TCP
  - name: http-otlp
    port: 4318        # HTTP OTLP
    protocol: TCP
  - name: prometheus
    port: 8889        # Prometheus 메트릭
    protocol: TCP
  selector:
    app.kubernetes.io/name: otel-collector-collector
```

## 4. Auto-Instrumentation 구성

### 4.1 Instrumentation 리소스 (`k8s-deploy/manifests/egov-monitoring/opentelemetry-instrumentation.yaml`)

#### 4.1.1 기본(default) 네임스페이스 구성
```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: otel-instrumentation
  namespace: default
spec:
  exporter:
    endpoint: http://otel-collector.egov-monitoring.svc.cluster.local:4318
  
  # 전파자 설정
  propagators:
    - tracecontext
    - baggage
    - b3
    - jaeger
  
  # 샘플링 설정
  sampler:
    type: parentbased_traceidratio
    argument: "0.1"  # 10% 샘플링
  
  # 리소스 속성
  resource:
    addK8sUIDAttributes: true
  
  # 환경 변수
  env:
    - name: OTEL_SERVICE_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.labels['app']
    - name: OTEL_SERVICE_VERSION
      valueFrom:
        fieldRef:
          fieldPath: metadata.labels['version']
    - name: OTEL_RESOURCE_ATTRIBUTES
      value: "k8s.cluster.name=egov,k8s.namespace.name=$(K8S_NAMESPACE),k8s.pod.name=$(K8S_POD_NAME)"
```

#### 4.1.2 애플리케이션(egov-app) 네임스페이스 구성
```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: otel-instrumentation
  namespace: egov-app
spec:
  exporter:
    endpoint: http://otel-collector.egov-monitoring.svc.cluster.local:4318
  
  propagators:
    - tracecontext
    - baggage
    - b3
    - jaeger
  
  sampler:
    type: parentbased_traceidratio
    argument: "1.0"  # 100% 샘플링 (개발/테스트 환경)
  
  # Java 계측 설정
  java:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:2.9.0
    env:
      - name: OTEL_JAVAAGENT_DEBUG
        value: "false"
      - name: OTEL_INSTRUMENTATION_JDBC_ENABLED
        value: "true"
      - name: OTEL_INSTRUMENTATION_SPRING_WEBMVC_ENABLED
        value: "true"
      - name: OTEL_INSTRUMENTATION_SPRING_WEBFLUX_ENABLED
        value: "true"
      - name: OTEL_INSTRUMENTATION_KAFKA_ENABLED
        value: "true"
      - name: OTEL_INSTRUMENTATION_REDIS_ENABLED
        value: "true"
  
  # 다중 언어 지원
  nodejs:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-nodejs:0.54.0
  python:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-python:0.48b0
  dotnet:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-dotnet:1.9.0
```

## 5. 애플리케이션 레벨 구성

### 5.1 Spring Boot 애플리케이션 설정

#### 5.1.1 application.yml 설정 (`EgovHello/src/main/resources/application.yml`)
```yaml
# OpenTelemetry 설정
otel:
  exporter:
    otlp:
      endpoint: http://otel-collector.egov-monitoring.svc.cluster.local:4317
  service:
    name: ${spring.application.name}
  traces:
    exporter: otlp
  metrics:
    exporter: otlp
  logs:
    exporter: otlp

# 로깅 패턴 (구조화된 로그)
logging:
  pattern:
    console: '{"timestamp":"%d{yyyy-MM-dd HH:mm:ss.SSS}","level":"%p","service":"${spring.application.name}","trace":"%X{trace_id}","span":"%X{span_id}","thread":"%t","logger":"%logger{63}","message":"%replace(%m){"\n", "\\n"}%n%ex"}'
```

#### 5.1.2 Logback 설정 (`EgovHello/src/main/resources/logback-spring.xml`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <!-- Console Appender - JSON 형식 -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="ch.qos.logback.core.encoder.LayoutWrappingEncoder">
            <layout class="ch.qos.logback.contrib.json.classic.JsonLayout">
                <timestampFormat>yyyy-MM-dd HH:mm:ss.SSS</timestampFormat>
                <jsonFormatter class="ch.qos.logback.contrib.jackson.JacksonJsonFormatter">
                    <prettyPrint>false</prettyPrint>
                </jsonFormatter>
                <appendLineSeparator>true</appendLineSeparator>
                <includeContextName>false</includeContextName>
                <includeThreadName>true</includeThreadName>
                <includeMDC>true</includeMDC>
                <includeException>true</includeException>
                <includeLoggerName>true</includeLoggerName>
            </layout>
        </encoder>
    </appender>

    <!-- OpenTelemetry Appender -->
    <appender name="OTEL" class="io.opentelemetry.instrumentation.logback.appender.v1_0.OpenTelemetryAppender">
        <captureExperimentalAttributes>true</captureExperimentalAttributes>
        <captureCodeAttributes>true</captureCodeAttributes>
        <encoder class="ch.qos.logback.core.encoder.LayoutWrappingEncoder">
            <layout class="ch.qos.logback.contrib.json.classic.JsonLayout">
                <timestampFormat>yyyy-MM-dd HH:mm:ss.SSS</timestampFormat>
                <jsonFormatter class="ch.qos.logback.contrib.jackson.JacksonJsonFormatter">
                    <prettyPrint>false</prettyPrint>
                </jsonFormatter>
            </layout>
        </encoder>
    </appender>

    <!-- 패키지별 로그 레벨 설정 -->
    <logger name="egovframework.com.hello" level="INFO" additivity="false">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="OTEL"/>
    </logger>

    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="OTEL"/>
    </root>
</configuration>
```

### 5.2 Kubernetes 배포 설정

#### 5.2.1 Deployment에 환경 변수 설정
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: egov-hello
  namespace: egov-app
spec:
  template:
    metadata:
      labels:
        app: egov-hello
        version: "v4.3.0"
    spec:
      containers:
      - name: egov-hello
        image: egovframe/egovhello:4.3.0.k8s
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "k8s"
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "http://otel-collector.egov-monitoring.svc.cluster.local:4317"
```

#### 5.2.2 Auto-Instrumentation 어노테이션 추가
```yaml
spec:
  template:
    metadata:
      annotations:
        instrumentation.opentelemetry.io/inject-java: "egov-app/otel-instrumentation"
      labels:
        app: egov-hello
        version: "v4.3.0"
```

## 6. Istio 통합 구성

### 6.1 Istio Telemetry 설정 (`k8s-deploy/manifests/egov-istio/telemetry.yaml`)
```yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: egov-apps-telemetry
  namespace: egov-app
spec:
  # 액세스 로깅
  accessLogging:
    - providers:
      - name: otel-loki
  
  # 분산 추적
  tracing:
    - randomSamplingPercentage: 100.0
      providers:
        - name: "otel-tracing"
      customTags:
        environment:
          environment:
            name: SPRING_PROFILES_ACTIVE
            defaultValue: "unknown"
        cluster:
          literal:
            value: "egov-cluster"
        version:
          header:
            name: x-version
            defaultValue: "unknown"
  
  # 메트릭 수집
  metrics:
    - providers:
        - name: prometheus
```

### 6.2 Istio ConfigMap 연동 (`k8s-deploy/manifests/egov-istio/config.yaml`)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: istio
  namespace: istio-system
data:
  mesh: |-
    extensionProviders:
    # OpenTelemetry 추적 설정
    - name: otel-tracing
      opentelemetry:
        service: otel-collector.egov-monitoring.svc.cluster.local
        port: 4317
    
    # Loki 로깅 설정
    - name: otel-loki
      envoyOtelAls:
        service: otel-collector.egov-monitoring.svc.cluster.local
        port: 4317
```

## 7. 모니터링 백엔드 연동

### 7.1 연동된 백엔드 시스템
- **Jaeger**: `jaeger-collector.egov-monitoring.svc.cluster.local:4317`
- **Tempo**: `tempo.egov-monitoring.svc.cluster.local:4317`
- **Prometheus**: `prometheus.egov-monitoring.svc.cluster.local:9090`
- **Loki**: `loki.egov-monitoring.svc.cluster.local:3100`

### 7.2 데이터 플로우
```
애플리케이션 → OpenTelemetry Collector → 백엔드 시스템
     ↓                    ↓                      ↓
  Traces              Jaeger/Tempo          분산 추적 시각화
  Metrics             Prometheus            메트릭 수집/저장
  Logs                Loki                  로그 수집/저장
```

## 8. 배포 및 관리

### 8.1 배포 순서
```bash
# 1. OpenTelemetry Operator 설치
kubectl apply -f k8s-deploy/manifests/egov-monitoring/opentelemetry-operator.yaml

# 2. OpenTelemetry Collector 배포
kubectl apply -f k8s-deploy/manifests/egov-monitoring/opentelemetry-collector.yaml

# 3. Instrumentation 설정 적용
kubectl apply -f k8s-deploy/manifests/egov-monitoring/opentelemetry-instrumentation.yaml

# 4. 애플리케이션 배포 (Auto-Instrumentation 적용)
kubectl apply -f k8s-deploy/manifests/egov-app/
```

### 8.2 상태 확인
```bash
# OpenTelemetry Operator 상태
kubectl get pods -n opentelemetry-operator-system

# Collector 상태
kubectl get pods -n egov-monitoring | grep otel-collector

# Instrumentation 확인
kubectl get instrumentation -A

# 애플리케이션 계측 상태 확인
kubectl describe pod <pod-name> -n egov-app
```

## 9. 점검 방법

### 9.1 일반적인 문제

#### 9.1.1 Auto-Instrumentation 확인
```bash
# Pod 어노테이션 확인
kubectl get pod <pod-name> -n egov-app -o yaml | grep instrumentation

# Operator 로그 확인
kubectl logs -n opentelemetry-operator-system deployment/opentelemetry-operator-controller-manager
```

#### 9.1.2 Collector 연결 확인
```bash
# Collector 로그 확인
kubectl logs -n egov-monitoring daemonset/otel-collector-collector

# 서비스 엔드포인트 확인
kubectl get svc otel-collector -n egov-monitoring
```

#### 9.1.3 데이터 전송 확인
```bash
# Collector 메트릭 확인
kubectl port-forward -n egov-monitoring svc/otel-collector 8889:8889
curl http://localhost:8889/metrics
```

### 9.2 디버깅 명령어
```bash
# OpenTelemetry 리소스 확인
kubectl get opentelemetrycollector -A
kubectl get instrumentation -A

# 계측된 Pod 확인
kubectl get pods -n egov-app -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.initContainers[0].image}{"\n"}{end}'

# Collector 설정 확인
kubectl get opentelemetrycollector otel-collector -n egov-monitoring -o yaml
```

## 10. 성능 최적화 방법

### 10.1 샘플링 설정
- **개발/테스트**: 100% 샘플링
- **프로덕션**: 필요에 따라 샘플링 비율 조정

### 10.2 배치 처리 최적화 (적절한 배치 크기 설정)
```yaml
processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
    send_batch_max_size: 2048
```

### 10.3 메모리 관리
가용 메모리 초과로 인한 서비스 중지 상황 방지
```yaml
processors:
  memory_limiter:
    check_interval: 5s
    limit_percentage: 80
    spike_limit_percentage: 25
```

## 11. 참고 자료

- [OpenTelemetry 공식 문서](https://opentelemetry.io/docs/)
- [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator)
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [프로젝트 OpenTelemetry 소개](/doc/intro/opentelemetry.md)

---
*이 문서는 eGovFrame MSA 프로젝트의 OpenTelemetry 구성을 기준으로 작성되었다.*

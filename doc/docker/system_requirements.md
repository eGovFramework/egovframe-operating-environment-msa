# 시스템 요구사항

## 1. 하드웨어 요구사항
- CPU: 4코어 이상 권장
- RAM: 최소 32GB 이상 권장 (OpenSearch 클러스터 운영을 위해)
- 디스크: 최소 50GB 이상의 여유 공간

## 2. 소프트웨어 요구사항
### 1) 운영체제
- Linux (Ubuntu 20.04 LTS 이상 권장)
- macOS 12 이상
- Windows 10/11 Pro 이상

### 2) 필수 소프트웨어
- Docker Engine 24.0.0 이상
- Docker Compose v2.20.0 이상
- Java Development Kit (JDK) 17 이상
- Git 2.34.1 이상

### 3) 네트워크
- 인터넷 연결 (컨테이너 이미지 다운로드용)
- 다음 포트들이 사용 가능해야 함:
    - 8761: Eureka Server
    - 8888: Config Server
    - 9000: API Gateway
    - 9200, 9600: OpenSearch
    - 5601: OpenSearch Dashboards
    - 3306: MySQL
    - 5672: RabbitMQ
    - 8081-8088: 마이크로서비스 포트 범위

## 3. 브라우저 요구사항 
- Chrome 112.0 이상
- Firefox 113.0 이상
- Safari 16.0 이상
- Edge 112.0 이상

## 4. 권장 개발 도구
- IntelliJ IDEA 2023.1 이상 또는 Eclipse 2023-03 이상
- Visual Studio Code 1.78 이상
- Postman 10.0 이상 또는 Swagger UI (API 테스트용)

## 5. 컨테이너 리소스 권장사항
각 컨테이너의 권장 리소스:
- Config Server: 512MB RAM
- Eureka Server: 512MB RAM
- API Gateway: 512MB RAM
- OpenSearch: 4GB RAM (노드당)
- 마이크로서비스: 각 1GB RAM

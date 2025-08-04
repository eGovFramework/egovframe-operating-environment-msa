# 아키텍처 구성도

## 1. 시스템 아키텍처

### 1) 인프라 서비스
```text
Gateway ┌ EurekaServer (Service Discovery / :8761)
        ├ ConfigServer (:8888)
        └ RabbitMQ (:5672)
```
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

### 2) 데이터 저장소
```text
─ MySQL (:3306)
┌ OpenSearch (:9200 / :9600)
└ OpenSearchDash (OpenSearch DashBoards / :5601)
```
   - **MySQL**
     - 주요 비즈니스 데이터 저장
     - 트랜잭션 처리
     - 관계형 데이터 관리
   
   - **OpenSearch**
     - 전문 검색 기능
     - 로그 수집 및 분석
     - 대시보드 시각화

### 3) 마이크로서비스
```text
Gateway ┌ EgovAuthor (:8081)
Config  ├ EgovBoard (:8082)
Eureka  ├ EgovCmmnCode (:8083)
Mysql   ├ EgovLogin (:8084)
        ├ EgovLoginPolicy (:8085)
        ├ EgovMain (:8086)
        ├ EgovMobileId (:8087)
        ├ EgovQuestionnaire (:8088)
        └ EgovSearch (:9992)
```
   - **Board Service**: 게시판 관리
   - **Author Service**: 권한 관리
   - **Main Service**: 메인 화면 및 포털 기능
   - **Login Service**: 인증 및 로그인 처리
   - **Login Policy Service** : 로그인 정책 관리
   - **MobileId Service**: 모바일 인증
   - **Questionnaire Service**: 설문조사
   - **Common Code Service**: 공통코드 관리
   - **Search Service**: 통합검색

### 4) 통신흐름
1. 클라이언트 요청 → API Gateway
2. API Gateway에서 인증/인가 처리
3. Service Discovery를 통한 서비스 위치 확인
4. 해당 마이크로서비스로 요청 라우팅
5. 마이크로서비스에서 비즈니스 로직 처리
6. 데이터 저장소 접근 및 결과 반환
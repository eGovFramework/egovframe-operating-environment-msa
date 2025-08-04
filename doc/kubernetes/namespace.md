
## 네임스페이스 (Namespace) / ConfigMap

### 1. 네임스페이스 생성 및 ConfigMap 배포
```bash
kubectl create namespace egov-app
kubectl create namespace egov-db
kubectl create namespace egov-infra
kubectl create namespace egov-monitoring
kubectl create namespace egov-storage
```

#### namespace에 연결된 pod
```text
egov-app ┬ egov-board
         ├ egov-author
         ├ egov-cmmnCode
         ├ egov-login
         ├ egov-loginPolicy
         ├ egov-main
         ├ egov-mobileId
         ├ egov-questionnire
         └ egov-search

egov-db ┬ mysql 
        ├ opensearch
        └ opensearch-dashboard


egov-infra ┬ rabbitMQ
           └ gatewayServer

egov-monitoring ┬ alertManager
                ├ grafana
                ├ jaeger
                ├ kiali
                ├ loki
                └ prometheus

egov-storage - nfs-provisioner
```

### 2. ConfigMap 적용
DB설정, Spring JPA, 인증토큰 등의 설정을 모아놓은 파일입니다.   

#### 1) `egov-common-configmap.yaml`
- DB 설정
    ```yaml
    # Database
    DATASOURCE_DRIVER_CLASS_NAME: "com.mysql.cj.jdbc.Driver"
    DATASOURCE_URL: "jdbc:mysql://mysql-0.mysql-headless.egov-db.svc.cluster.local:3306/com"
    
    # HikariCP
    SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE: "20"
    SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT: "20000"
    SPRING_DATASOURCE_HIKARI_IDLE_TIMEOUT: "30000"
    SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE: "5"
    SPRING_DATASOURCE_HIKARI_MAX_LIFETIME: "1800000"

        # MySQL Character Set
    MYSQL_CHARACTER_SET: "utf8mb4"
    MYSQL_COLLATION: "utf8mb4_unicode_ci"
    MYSQL_LOWER_CASE_TABLE_NAMES: "1"
    ```
    - JPA
    ```yaml
    # JPA
    SPRING_JPA_HIBERNATE_DDL_AUTO: "update"
    SPRING_JPA_OPEN_IN_VIEW: "false"
    SPRING_JPA_SHOW_SQL: "true"
    SPRING_JPA_PROPERTIES_HIBERNATE_FORMAT_SQL: "true"
    ```

- 인증 Token
    ```yaml
    # Token Configuration
    TOKEN_ACCESS_SECRET: "7FB814B9D7FFB3D675EF1F525C1D61B254227B3B0A771DDDBDFE4112A1F42F66"
    TOKEN_REFRESH_SECRET: "7FB814B9D7FFB3D675EF1F525C1D61B254227B3B0A771DDDBDFE4112A1F42F66"
    TOKEN_ACCESS_EXPIRATION: "1200000"
    TOKEN_REFRESH_EXPIRATION: "3600000"
    ```

- 사용자 권한 지정
    ```yaml
    # Security Role
    ROLES_ROLE_ADMIN: ROLE_ADMIN
    ROLES_ROLE_USER: ROLE_USER
    ```

- APIGateway에서 허용할 IP 지정   
    ```yaml
    APIGATEWAY_ALLOWED_ORIGIN: http://localhost:9000,http://<서버의 IP>:9000
    ```
    *','로 구분하여 여러개 지정 가능

- 파일 업로드 다운로드
    ```yaml
    # File Upload Configuration
    FILE_CK_UPLOAD_DIR: "/app/upload/ckeditor"
    FILE_CK_ALLOWED_EXTENSIONS: "jpg,jpeg,gif,bmp,png"
    FILE_BOARD_UPLOAD_DIR: "/app/upload/board"
    FILE_BOARD_ALLOWED_EXTENSIONS: "jpg,jpeg,gif,bmp,png,pdf"
    FILE_MAX_FILE_SIZE: "1048576"
    ```
    - EgovBoard (게시판) 서비스에서 사용
    - Ckeditor의 이미지와 게시판 첨부파일 관리

#### 2) configmap 배포
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/common/egov-common-configmap.yaml -n egov-app
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/common/egov-common-configmap.yaml -n egov-infra
```

---
<div align="center">
   <table>
     <tr>
       <th>Step1. Namespace 생성</th>
       <th><a href="istio.md">Step2. Istio 배포 ▷</a></th>
     </tr>
   </table>
</div>
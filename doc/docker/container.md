# 컨테이너 구성 
## 1. 기본 컨테이너
| 컨테이너명 | 이미지 | 기본 포트 | 볼륨 마운트 | 의존성 |
|------------|--------|------------|--------------|---------|
| config-server | configserver:${IMAGE_TAG} | 8888 | ${CONFIG_LOCAL_PATH}:/config-repo | opensearch, bbs_rabbitmq |
| eureka-server | eurekaserver:${IMAGE_TAG} | 8761 | - | config-server |
| gateway-server | gatewayserver:${IMAGE_TAG} | 9000 | - | config-server, eureka-server |
| mysql-com | mysql:8.0 | 3306 | mysql_data:/var/lib/mysql | - |
| opensearch | opensearch-with-nori:2.15.0 | 9200, 9600 | opensearch-data1:/usr/share/opensearch/data | - |
| bbs_rabbitmq | rabbitmq:3-management | 5672, 15672 | rabbitmq_data:/var/lib/rabbitmq | - |

## 2. 마이크로서비스 컨테이너
| 컨테이너명              | 이미지                            | 기본 포트 | 의존성                                   |
| ------------------ | ------------------------------ | ----- | ------------------------------------- |
| egov-author        | egovauthor:${IMAGE_TAG}        | 8081  | mysql-com, gateway-server, config-server             |
| egov-board         | egovboard:${IMAGE_TAG}         | 8082  | mysql-com, gateway-server, config-server             |
| egov-cmmncode      | egovcmmncode:${IMAGE_TAG}      | 8083  | mysql-com, gateway-server, config-server             |
| egov-login         | egovlogin:${IMAGE_TAG}         | 8084  | mysql-com, gateway-server, config-server             |
| egov-login-policy  | egovloginpolicy:${IMAGE_TAG}   | 8085  | mysql-com, gateway-server, config-server             |
| egov-main          | egovmain:${IMAGE_TAG}          | 8086  | mysql-com, gateway-server             |
| egov-questionnaire | egovquestionnaire:${IMAGE_TAG} | 8088  | mysql-com, gateway-server, config-server                        |
| egov-search        | egovsearch:${IMAGE_TAG}        | 9992  | opensearch, mysql-com, gateway-server, config-server |

## 3. 볼륨 구성
```yaml
volumes:
  opensearch-data1:    # OpenSearch 데이터 저장
    driver: local
    driver_opts:
      type: none
      device: ${OPENSEARCH_DATA_PATH}
      o: bind
      
  rabbitmq_data:      # RabbitMQ 데이터 저장
    driver: local
    driver_opts:
      type: none
      device: ${RABBITMQ_DATA_PATH}
      o: bind
      
  mysql_data:         # MySQL 데이터 저장
    driver: local
    driver_opts:
      type: none
      device: ${MYSQL_DATA_PATH}
      o: bind
```

## 4. 네트워크 구성
- 네트워크명: `egov-msa-com`
- 타입: bridge
- 구성방식: 
  ```bash
  docker network create egov-msa-com
  ```

## 5. 환경변수 구성
```properties
# 공통 설정
DOCKER_REGISTRY=localhost:5000
IMAGE_TAG=latest
NETWORK_NAME=egov-msa-com

# MySQL 설정
MYSQL_PORT=3306
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=com
MYSQL_USER=com
MYSQL_PASSWORD=com01

# RabbitMQ 설정
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_PORT=5672

# 서비스 포트
CONFIG_SERVER_PORT=8888
EUREKA_SERVER_PORT=8761
GATEWAY_SERVER_PORT=9000
```

## 6. 스케일링 구성
Board 서비스의 수평적 확장 지원:
- egov-board-2: 포트 8092
- egov-board-3: 포트 8093
```yaml
services:
  egov-board-2:
    image: egovboard:${IMAGE_TAG}
    ports:
      - "${EGOV_BOARD_PORT_2:-8092}:${EGOV_BOARD_PORT:-8082}"
      
  egov-board-3:
    image: egovboard:${IMAGE_TAG}
    ports:
      - "${EGOV_BOARD_PORT_3:-8093}:${EGOV_BOARD_PORT:-8082}"
```

## 7. 헬스체크 구성
모든 서비스는 다음과 같은 헬스체크 설정을 포함:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:${PORT}/actuator/health || exit 1
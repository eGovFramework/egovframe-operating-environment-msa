FROM openjdk:8-jre-slim
WORKDIR /app

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY target/*.jar /app/app.jar

ENV SERVER_PORT=8083 \
    SPRING_APPLICATION_NAME=EgovCmmnCode \
    SPRING_PROFILES_ACTIVE=local \
    EUREKA_CLIENT_SERVICE-URL_DEFAULTZONE=http://eureka-server:8761/eureka/ \
    SPRING_CLOUD_CONFIG_URI=http://config-server:8888 \
    SPRING_RABBITMQ_HOST=bbs_rabbitmq \
    MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE="*" \
    MANAGEMENT_ENDPOINT_HEALTH_SHOW-DETAILS=always

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8083/actuator/health || exit 1

EXPOSE 8083

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app/app.jar"]
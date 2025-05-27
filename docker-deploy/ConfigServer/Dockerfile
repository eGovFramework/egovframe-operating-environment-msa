FROM openjdk:8-jre-slim
WORKDIR /app

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY target/*.jar /app/app.jar

ENV SERVER_PORT=8888 \
    SPRING_APPLICATION_NAME=ConfigServer \
    SPRING_PROFILES_ACTIVE=native,default \
    SPRING_CLOUD_CONFIG_SERVER_NATIVE_SEARCH_LOCATIONS=file:/config-repo \
    SPRING_RABBITMQ_HOST=bbs_rabbitmq \
    SPRING_RABBITMQ_PORT=5672 \
    SPRING_RABBITMQ_USERNAME=guest \
    SPRING_RABBITMQ_PASSWORD=guest \
    MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE="*" \
    MANAGEMENT_ENDPOINT_HEALTH_SHOW-DETAILS=always

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8888/actuator/health || exit 1

EXPOSE 8888

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app/app.jar"]

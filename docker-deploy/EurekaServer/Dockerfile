FROM openjdk:8-jre-slim
WORKDIR /app

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY target/*.jar /app/app.jar

ENV SERVER_PORT=8761 \
    SPRING_APPLICATION_NAME=EurekaServer \
    SPRING_PROFILES_ACTIVE=default \
    MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE="*" \
    MANAGEMENT_ENDPOINT_HEALTH_SHOW-DETAILS=always

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8761/actuator/health || exit 1

EXPOSE 8761

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app/app.jar"]
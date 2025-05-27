FROM openjdk:8-jre-slim
WORKDIR /app

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY target/*.jar /app/app.jar

ENV SERVER_PORT=8084 \
    SPRING_APPLICATION_NAME=EgovLogin \
    SPRING_PROFILES_ACTIVE=docker \
    SPRING_CLOUD_CONFIG_URI=http://config-server:8888

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8084/actuator/health || exit 1

EXPOSE 8084

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app/app.jar"]
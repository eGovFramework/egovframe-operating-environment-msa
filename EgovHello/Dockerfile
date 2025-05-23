FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY target/*.jar /app/app.jar

ENV SERVER_PORT=8086 \
    SPRING_APPLICATION_NAME=EgovHello \
    SPRING_PROFILES_ACTIVE=docker \
    SPRING_CLOUD_CONFIG_URI=http://config-server:8888 \
    OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8086/actuator/health || exit 1

EXPOSE 8086

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app/app.jar"]
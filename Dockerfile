# ----------------------------------------------------------------------
# - DOCKERFILE
# - AUTOR: Wilman Ortiz
# - FECHA: 20-Marzo-2023
# - DESCRIPCION: Dockerfile allows us to test hexagonal architecture
# - BUILD-COMMAND: DOCKER_BUILDKIT=1 docker build --no-cache=true --build-arg BUILD_VERSION="v1.0.0-$(date '+%Y%m%d%H%M%S')" --tag=wortiz1027/employee-services:"v1.0.0-$(date '+%Y%m%d%H%M%S')" --rm=true .
# - https://stackoverflow.com/questions/51115856/docker-failed-to-export-image-failed-to-create-image-failed-to-get-layer
# - https://www.rajith.me/2021/04/create-optimized-spring-boot-docker.html
# - https://github.com/Rajithkonara/rest-localization
# -----------------------------------------------------------------------

FROM gradle:8.0.2-jdk17-alpine AS generator
ENV APP_HOME=/artifact/
WORKDIR /artifact/
COPY --chown=gradle:gradle build.gradle settings.gradle .
COPY --chown=gradle:gradle src ./src
RUN gradle build -x test --no-daemon

FROM openjdk:20-ea-17-slim AS builder
WORKDIR source
ENV HTTP_PORT=8080 \
    MONITOR_PORT=9090
ARG JAR_FILE=laboratory1-services.jar
COPY --from=generator /artifact/build/libs/$JAR_FILE application.jar
EXPOSE $HTTP_PORT $MONITOR_PORT
RUN java -Djarmode=layertools -jar application.jar extract

FROM openjdk:20-ea-17-slim
WORKDIR app
COPY --from=builder source/dependencies/ ./
COPY --from=builder source/spring-boot-loader/ ./
COPY --from=builder source/snapshot-dependencies/ ./
COPY --from=builder source/application/ ./

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]

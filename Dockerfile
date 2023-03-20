# ----------------------------------------------------------------------
# - DOCKERFILE
# - AUTOR: Wilman Ortiz
# - FECHA: 20-Marzo-2023
# - DESCRIPCION: Dockerfile allows us to test hexagonal architecture
# - BUILD-COMMAND: DOCKER_BUILDKIT=1 docker build --no-cache=true --build-arg BUILD_DATE="$(date '+%Y-%m-%d %H:%M:%S')" --build-arg BUILD_VERSION="v1.0.0-$(date '+%Y%m%d%H%M%S')" --tag=wortiz1027/employee-services:"v1.0.0-$(date '+%Y%m%d%H%M%S')" --rm=true .
# - https://stackoverflow.com/questions/51115856/docker-failed-to-export-image-failed-to-create-image-failed-to-get-layer
# - https://www.rajith.me/2021/04/create-optimized-spring-boot-docker.html
# - https://github.com/Rajithkonara/rest-localization
# -----------------------------------------------------------------------
ARG BUILD_HOME=/application

FROM gradle:8.0.2-jdk17-alpine AS generator
ARG BUILD_HOME
ENV APP_HOME=$BUILD_HOME
WORKDIR $APP_HOME
COPY --chown=gradle:gradle build.gradle settings.gradle $APP_HOME/
COPY --chown=gradle:gradle src $APP_HOME/src
COPY --chown=gradle:gradle config $APP_HOME/config
RUN gradle clean build --no-daemon

FROM openjdk:20-ea-17-slim AS builder
WORKDIR source
ENV HTTP_PORT=8080 \
    MONITOR_PORT=9090
ARG JAR_FILE=clients-services.jar
COPY --from=generator /build/libs/$JAR_FILE application.jar
EXPOSE $HTTP_PORT $MONITOR_PORT
RUN java -Djarmode=layertools -jar application.jar extract

FROM openjdk:20-ea-17-slim

WORKDIR app

ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REVISION

LABEL org.opencontainers.image.created=$BUILD_DATE \
	  org.opencontainers.image.authors="Wilman Ortiz Navarro " \
	  org.opencontainers.image.url="https://github.com/wortiz1027/laboratory1/blob/master/Dockerfile" \
	  org.opencontainers.image.documentation="" \
	  org.opencontainers.image.source="https://github.com/wortiz1027/laboratory1/blob/master/Dockerfile" \
	  org.opencontainers.image.version=$BUILD_VERSION \
	  org.opencontainers.image.revision=$BUILD_REVISION \
	  org.opencontainers.image.vendor="https://developer.io" \
	  org.opencontainers.image.licenses="" \
	  org.opencontainers.image.title="Hexagonal Architecture" \
	  org.opencontainers.image.description="This service try to show us how hexagonal architecture works"

COPY --from=builder source/dependencies/ ./
COPY --from=builder source/spring-boot-loader/ ./
COPY --from=builder source/snapshot-dependencies/ ./
COPY --from=builder source/application/ ./

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]

# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: Prepare java build environment
# ─────────────────────────────────────────────────────────────────────────────
# Strimzi 1.1.0 sets maven.compiler.release to 21, so the builder needs a JDK 21.
FROM maven:3.9-eclipse-temurin-21 AS build-env

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    make git zip unzip curl xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh

# Install shellcheck
RUN curl -L https://github.com/koalaman/shellcheck/releases/download/v0.9.0/shellcheck-v0.9.0.linux.x86_64.tar.xz | tar -xJ && \
    cp shellcheck-v0.9.0/shellcheck /usr/local/bin/ && \
    chmod +x /usr/local/bin/shellcheck && \
    rm -rf shellcheck-v0.9.0*

# Install yq
RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# Install helm
RUN curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz && \
    tar -xzf helm.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm -rf linux-amd64 helm.tar.gz

# Add source code
WORKDIR /app
COPY . .

# Download Kafka authorizer.
#
# Keep AUTHORIZER_VERSION in step with the <version> of the hops-kafka-authorizer
# dependency in docker-images/artifacts/kafka-thirdparty-libs/*/pom.xml — the pom
# resolves this jar from /tmp by systemPath, so a mismatch is not caught by Maven.
# Fail loudly if the download did not produce a jar, otherwise the Kafka image is
# built with an empty/HTML file in ${KAFKA_HOME}/libs and the broker starts without
# an authorizer.
ARG AUTHORIZER_VERSION=5.1.0-SNAPSHOT
RUN curl -fsSL -o /tmp/hops-kafka-authorizer.jar \
      "https://repo.hops.works/master/hops-kafka-authorizer/${AUTHORIZER_VERSION}/hops-kafka-authorizer-${AUTHORIZER_VERSION}.jar" && \
    unzip -t /tmp/hops-kafka-authorizer.jar > /dev/null && \
    unzip -l /tmp/hops-kafka-authorizer.jar | grep -q 'io/hops/kafka/HopsAclAuthorizer.class'

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: Install strimzi-kafka-operator
# ─────────────────────────────────────────────────────────────────────────────
FROM build-env AS build-strimzi

WORKDIR /app

RUN mvn clean install -DskipTests

RUN make MVN_ARGS='-DskipTests' java_install

# ─────────────────────────────────────────────────────────────────────────────
# Stage 3: Extract docker images
# ─────────────────────────────────────────────────────────────────────────────
FROM alpine AS final

COPY --from=build-strimzi /app/docker-images /docker-images
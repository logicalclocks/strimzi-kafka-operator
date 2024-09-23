# Deployment

## Prerequsites

### Authorizer

If you want to deploy changes to the authorizer build it beforehand:
https://github.com/logicalclocks/hops-kafka-authorizer/blob/master/README.md

### Java

Use Java 17 for deploying Strimzi!

## Deployment

Specify where to push the finished docker images:

```sh
export DOCKER_ORG=strimzi  # set to dev/YOUR_NAME/strimzi for personal development
export DOCKER_REGISTRY=docker.hops.works  # defaults to docker.io if unset
export DOCKER_TAG=0.39.0
```

Clean previous build:

```sh
make clean
```

Build and push images:

```sh
make MVN_ARGS='-DskipTests' all
```

## Updating hopsworks

Specify the new authorizer version here:

https://github.com/logicalclocks/strimzi-kafka-operator/blob/release-0.39.x/docker-images/artifacts/kafka-thirdparty-libs/3.5.x/pom.xml#L70
https://github.com/logicalclocks/strimzi-kafka-operator/blob/release-0.39.x/docker-images/artifacts/kafka-thirdparty-libs/3.6.x/pom.xml#L73

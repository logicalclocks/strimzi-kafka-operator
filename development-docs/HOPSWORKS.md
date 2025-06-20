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
export DOCKER_REGISTRY=dev5.devnet.hops.works:5043  # defaults to docker.io if unset
export DOCKER_ORG=ralfs_mini_registry/strimzi
export DOCKER_TAG=0.46.0
```

Clean previous build:

```sh
make clean
```

Build and push images:

```sh
make MVN_ARGS='-DskipTests' all
```

## Testing

Make sure you set `defaultImageRepository` according to the value provided in `DOCKER_ORG`

https://github.com/logicalclocks/hopsworks-helm/

Or in existing cluster 

# Updating hopsworks

Specify the new authorizer version here:

* [3.5.x](../docker-images/artifacts/kafka-thirdparty-libs/3.5.x/pom.xml#L70)
* [3.6.x](../docker-images/artifacts/kafka-thirdparty-libs/3.6.x/pom.xml#L73)

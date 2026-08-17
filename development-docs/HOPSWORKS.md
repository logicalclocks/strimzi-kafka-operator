# Deployment

## Prerequsites

### Authorizer

If you want to deploy changes to the authorizer build it beforehand:

https://github.com/logicalclocks/hops-kafka-authorizer/blob/master/README.md

### Java

Use Java 21 for deploying Strimzi — the 1.x line sets `maven.compiler.release` to 21.
(The 0.45.x line needed Java 17.)

## Deployment

Specify where to push the finished docker images:

```sh
export DOCKER_REGISTRY=dev5.devnet.hops.works:5043  # defaults to docker.io if unset
export DOCKER_ORG=ralfs_mini_registry/strimzi
export DOCKER_TAG=1.1.0
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

Or in existing cluster update `strimzi-cluster-operator` deployment.

# Updating hopsworks

## Authorizer version

The authorizer version is declared in **two** places and both must agree — the
third-party-libs poms resolve the jar from `/tmp` by `systemPath`, so Maven will not
catch a mismatch:

1. `AUTHORIZER_VERSION` in the root [Dockerfile](../Dockerfile) (what gets downloaded).
2. The `hops-kafka-authorizer` `<version>` in every supported Kafka version's pom:
   * [4.2.0](../docker-images/artifacts/kafka-thirdparty-libs/4.2.0/pom.xml)
   * [4.2.1](../docker-images/artifacts/kafka-thirdparty-libs/4.2.1/pom.xml)
   * [4.3.x](../docker-images/artifacts/kafka-thirdparty-libs/4.3.x/pom.xml)

When Strimzi adds or drops a supported Kafka version, `kafka-versions.yaml` gains or
loses an entry and a new `kafka-thirdparty-libs/<version>` directory appears. Add the
authorizer dependency to it, or the Kafka image for that version ships without an
authorizer and every broker fails to start.

The authorizer must be built against a Kafka version in Strimzi's supported set, and it
must shade in guava — Strimzi stopped shipping guava in the Kafka image's third-party
libs in 1.1.0.

## Consuming the images

Set `strimzi-kafka-operator.defaultImageRegistry` / `defaultImageRepository` /
`defaultImageTag` in `charts/kafka/values.yaml`, and `cluster.kafka.version` to a Kafka
version this build published:

https://github.com/logicalclocks/hopsworks-helm/

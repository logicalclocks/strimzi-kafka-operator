# Deployment

## Prerequsites

### Authorizer

If you want to deploy changes to the authorizer build it beforehand:

https://github.com/logicalclocks/hops-kafka-authorizer/blob/master/README.md

Then point this build at the jar it produced, otherwise the version declared in the
third-party-libs poms is downloaded from `repo.hops.works` instead:

```sh
export AUTHORIZER_JAR=~/hops-kafka-authorizer/target/hops-kafka-authorizer-<version>.jar
```

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

The authorizer version is declared once, as the `hops-kafka-authorizer` `<version>` in
every supported Kafka version's third-party-libs pom:

* [4.2.0](../docker-images/artifacts/kafka-thirdparty-libs/4.2.0/pom.xml)
* [4.2.1](../docker-images/artifacts/kafka-thirdparty-libs/4.2.1/pom.xml)
* [4.3.x](../docker-images/artifacts/kafka-thirdparty-libs/4.3.x/pom.xml)

The dependency is `system`-scoped, so Maven never downloads it. Instead
[build.sh](../docker-images/artifacts/build.sh) reads the version and the `systemPath`
out of those poms and fetches the jar from `repo.hops.works` (override the base URL with
`AUTHORIZER_BASE_URL`) before `dependency:copy-dependencies` runs. That happens for every
way into the build — `docker build` with the root [Dockerfile](../Dockerfile), CI running
`make java_install` on the runner, and local `make` — so there is nothing to keep in sync.

Set `AUTHORIZER_JAR` to a locally built jar to use that instead of downloading a published
one; that is how unreleased authorizer changes get into an image. The jar is checked for
`io.hops.kafka.HopsAclAuthorizer` either way, but nothing verifies that a local jar's
version matches the one declared in the poms — that is on you.

When Strimzi adds or drops a supported Kafka version, `kafka-versions.yaml` gains or
loses an entry and a new `kafka-thirdparty-libs/<version>` directory appears. Add the
authorizer dependency to it — the build fails with a message pointing at the pom if you
do not, rather than shipping a Kafka image whose brokers cannot start.

The authorizer must be built against a Kafka version in Strimzi's supported set, and it
must shade in guava — Strimzi stopped shipping guava in the Kafka image's third-party
libs in 1.1.0.

## Consuming the images

Set `strimzi-kafka-operator.defaultImageRegistry` / `defaultImageRepository` /
`defaultImageTag` in `charts/kafka/values.yaml`, and `cluster.kafka.version` to a Kafka
version this build published:

https://github.com/logicalclocks/hopsworks-helm/

# Hopsworks CRD carrier image.
#
# Helm only applies a chart's crds/ directory on install and never on upgrade, so
# hopsworks-helm refreshes the Strimzi CRDs from a pre-upgrade hook Job instead. That Job
# needs the CRDs for the exact operator version it is upgrading to, plus a kubectl to
# apply them with, hence this image.
#
# It is built here rather than in hopsworks-helm on purpose: the CRDs are copied straight
# out of this checkout, so the image content cannot drift from the operator version it
# ships with.
#
# Build from the repository root:
#   make -f Makefile.hopsworks docker_build_crds
FROM alpine:3.21

ARG KUBECTL_VERSION=v1.34.1
ARG TARGETARCH=amd64

# bash: the consuming Job runs a bash script, matching the other CRD-upgrade hooks in
# hopsworks-helm. kubectl checksum is verified because a truncated download would only
# surface as a confusing apply error inside the hook.
RUN apk add --no-cache bash ca-certificates curl && \
    curl -fsSLo /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" && \
    curl -fsSLo /tmp/kubectl.sha256 \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl.sha256" && \
    echo "$(cat /tmp/kubectl.sha256)  /usr/local/bin/kubectl" | sha256sum -c - && \
    rm -f /tmp/kubectl.sha256 && \
    chmod +x /usr/local/bin/kubectl && \
    apk del curl

# The CRDs the matching operator version expects. Kept at a stable path so the consuming
# hook does not have to know the version.
COPY packaging/install/cluster-operator/*Crd*.yaml /srv/hops/strimzi-crds/

# Fail the build rather than ship an image with no CRDs in it - the glob above silently
# produces an empty directory if upstream renames the files.
RUN test "$(find /srv/hops/strimzi-crds -name '*.yaml' | wc -l)" -gt 0 && \
    ls -1 /srv/hops/strimzi-crds/

# Runs under an arbitrary UID on OpenShift; everything it needs is world-readable.
USER 1001

ENTRYPOINT ["/bin/bash"]

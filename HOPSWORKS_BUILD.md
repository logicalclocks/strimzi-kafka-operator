# Hopsworks build

We need to be able to build new Strimzi images where the only difference is using a most fresh base image with vulnerability fixes.

The images are created by simply re-tagging the upstream images. To tag and push with the Hopsworks tag use `Makefile.hopsworks`

To build new Hopsworks images you need to change the `hopsworks.version` file.

If you are running the Jenkins pipeline, consider disabling `PUSH_UPSTREAM_TAGGED_IMAGES` otherwise push might fail because the upstream tagged images (without the Hopsworks patch) will already exist and we disable images mutation.

## Usage

`make -f Makefile.hopsworks show` will print the images to be re-tagged and pushed. It is a **DRY-RUN** operation.

### Multi-architecture (amd64 + arm64)

```bash
# Tag and push per architecture
DOCKER_ARCHITECTURE=amd64 make -f Makefile.hopsworks docker_retag docker_push
DOCKER_ARCHITECTURE=arm64 make -f Makefile.hopsworks docker_retag docker_push

# Create and push manifest lists
MANIFEST_ARCHITECTURES=amd64,arm64 make -f Makefile.hopsworks docker_amend_manifest
```

### Single architecture

```bash
make -f Makefile.hopsworks docker_retag docker_push
```

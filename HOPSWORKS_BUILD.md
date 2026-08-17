# Hopsworks build

We need to be able to build new Strimzi images where the only difference is using a most fresh base image with vulnerability fixes.

The images are created by simply re-tagging the upstream images. To tag and push with the Hopsworks tag use `Makefile.hopsworks`

To build new Hopsworks images you need to change the `hopsworks.version` file.

If you are running the Jenkins pipeline, consider disabling `PUSH_UPSTREAM_TAGGED_IMAGES` otherwise push might fail because the upstream tagged images (without the Hopsworks patch) will already exist and we disable images mutation.

## Usage

`make -f Makefile.hopsworks show` will print the images to be re-tagged and pushed. It is a **DRY-RUN** operation.

`make -f Makefile.hopsworks docker_retag` will tag the images with the Hopsworks patch version

`make -f Makefile.hopsworks docker_push` will push the images

## The CRD image

`crds:<release>-<hopsworks>` is the one image here that is **built** rather than re-tagged,
because it has no upstream equivalent. It carries this checkout's
`packaging/install/cluster-operator/*Crd*.yaml` plus a `kubectl`, and exists because Helm
only applies a chart's `crds/` directory on install, never on upgrade — so hopsworks-helm
refreshes the Strimzi CRDs from a pre-upgrade hook Job, which needs them in an image.

Building it from this repo rather than from hopsworks-helm is deliberate: the CRDs are
copied out of the same checkout that produces the operator image, so the two cannot drift.

`make -f Makefile.hopsworks docker_build_crds` builds it, `docker_push_crds` pushes it, and
both are wired into `docker_retag` / `docker_push` so `all` covers them.
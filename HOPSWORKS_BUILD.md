# Hopsworks build

We need to be able to build new Strimzi images where the only difference is using a most fresh base image with vulnerability fixes.

The images are created by simply re-tagging the upstream images. To tag and push with the Hopsworks tag use `Makefile.hopsworks`

`make -f Makefile.hopsworks show` will print the images to be re-tagged and pushed. It is a **DRY-RUN** operation.

`make -f Makefile.hopsworks docker_retag` will tag the images with the Hopsworks patch version

`make -f Makefile.hopsworks docker_push` will push the images
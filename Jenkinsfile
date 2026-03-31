@Library("jenkins-library@main")

import com.logicalclocks.jenkins.k8s.ImageBuilder

def ARCHITECTURES = ['amd64', 'arm64']
def MANIFEST_ARCHITECTURES = ARCHITECTURES.join(',')

pipeline {
  agent { label 'local' }

  parameters {
    booleanParam(name: 'PUSH_UPSTREAM_TAGGED_IMAGES', defaultValue: true, description: 'Push Strimzi images with the upstream version. Disable if you only want to push Hopsworks tagged images')
  }

  stages {
        stage('Clone repository') {
            steps {
                checkout scm
            }
        }
        stage('Setup multi-platform builds') {
            steps {
                sh """
                    # Verify Docker 24+ (required for manifest list support)
                    DOCKER_VERSION=\$(docker version --format '{{.Client.Version}}' | cut -d. -f1)
                    if [ "\$DOCKER_VERSION" -lt 24 ]; then
                        echo "ERROR: Docker 24+ is required for manifest list support, found version \$DOCKER_VERSION"
                        exit 1
                    fi

                    # Register QEMU for cross-platform emulation
                    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
                """
            }
        }
        stage('Build extract image and prepare artifacts') {
            steps {
                sh """
                    # Remove container if it already exists
                    docker rm -f extract-container 2>/dev/null || true

                    # Remove all dangling images (to save space)
                    docker image prune -f

                    # Build the image
                    docker build -t strimzi/image-builder:1.0 .

                    # Create container
                    docker create --name extract-container strimzi/image-builder:1.0

                    # Copy out the generated docker images (using tar to avoid permission issues)
                    docker cp extract-container:/docker-images - | tar -xf - --strip-components=1 -C ./docker-images

                    # Remove container
                    docker rm -f extract-container
                """
            }
        }
        // INFO: I tried to use build-manifest.json but strimzi creates mutiple images
        // and it will be hard to maintain it. Also some images like strimzi/base
        // are meant to be created and used only locally to create other images,
        // but current image builder doesnt allow it (it tries to download it).
        stage('Build images for all architectures') {
            steps {
                script {
                    ARCHITECTURES.each { arch ->
                        echo "Building all images for architecture: ${arch}"
                        sh """
                            export DOCKER_ARCHITECTURE=${arch}
                            make docker_build
                        """
                    }
                }
            }
        }
        stage('Push images and create manifests') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'a0770738-4ef3-4acc-a6ba-097ee6c85b44', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                    script {
                        def version = readFile("release.version").trim()
                        def builder = new ImageBuilder(this)

                        builder.REGISTRIES.each { reg ->
                            reg.auth()
                            def registryUrl = reg.buildImageName("", "").replaceFirst(/\/:$/, '')

                            // Tag and push each architecture
                            ARCHITECTURES.each { arch ->
                                sh """
                                    export DOCKER_REGISTRY=${registryUrl}
                                    export DOCKER_ORG=strimzi
                                    export DOCKER_TAG=${version}
                                    export DOCKER_ARCHITECTURE=${arch}

                                    make docker_tag
                                    ${params.PUSH_UPSTREAM_TAGGED_IMAGES ? 'make docker_push' : 'echo "Skipping upstream image push"'}
                                """
                            }

                            // Create and push upstream manifest lists (multi-arch image references)
                            if (params.PUSH_UPSTREAM_TAGGED_IMAGES) {
                                sh """
                                    export DOCKER_REGISTRY=${registryUrl}
                                    export DOCKER_ORG=strimzi
                                    export DOCKER_TAG=${version}
                                    export MANIFEST_ARCHITECTURES="${MANIFEST_ARCHITECTURES}"
                                    make docker_amend_manifest
                                """
                            }

                            // Hopsworks re-tagging: tag and push per architecture
                            ARCHITECTURES.each { arch ->
                                sh """
                                    export DOCKER_REGISTRY=${registryUrl}
                                    export DOCKER_ARCHITECTURE=${arch}
                                    make -f Makefile.hopsworks docker_retag docker_push
                                """
                            }

                            // Create and push Hopsworks manifest lists
                            sh """
                                export DOCKER_REGISTRY=${registryUrl}
                                export MANIFEST_ARCHITECTURES="${MANIFEST_ARCHITECTURES}"
                                make -f Makefile.hopsworks docker_amend_manifest
                            """
                        }
                    }
                }
            }
        }
    }
}

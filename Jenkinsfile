@Library("jenkins-library@main")

import com.logicalclocks.jenkins.k8s.ImageBuilder

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
        stage('Build and push images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'a0770738-4ef3-4acc-a6ba-097ee6c85b44', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                    script {
                        // Build the extract image and get the docker-images
                        sh """
                            # Remove container if it already exists
                            docker rm -f extract-container 2>/dev/null || true

                            # Remove all dangling images (to save space)
                            docker image prune

                            # Build the image
                            docker build -t strimzi/image-builder:1.0 .

                            # Create container
                            docker create --name extract-container strimzi/image-builder:1.0

                            # Copy out the generated docker images
                            docker cp extract-container:/docker-images/. ./docker-images

                            # Remove container
                            docker rm -f extract-container
                        """

                        // INFO: I tried to use build-manifest.json but strimzi creates mutiple images
                        // and it will be hard to maintain it. Also some images like strimzi/base
                        // are meant to be created and used only locally to create other images, 
                        // but current image builder doesnt allow it (it tries to download it).

                        def version = readFile("release.version").trim()

                        // Build the Docker image
                        sh """
                            make docker_build
                        """

                        def builder = new ImageBuilder(this)

                        // Push the Docker image
                        builder.REGISTRIES.each { reg ->
                            // Authenticate to the registry
                            reg.auth()

                            // Get registryUrl
                            def registryUrl = reg.buildImageName("", "").replaceFirst(/\/:$/, '')

                            // Push the image
                            sh """
                                export DOCKER_REGISTRY=${registryUrl}
                                export DOCKER_ORG=strimzi
                                export DOCKER_TAG=${version}
                                
                                make docker_tag
                                ${params.PUSH_UPSTREAM_TAGGED_IMAGES ? 'make docker_push' : 'echo "Skipping pushing upstream tagged images"'}

                                make -f Makefile.hopsworks all
                            """
                        }
                    }
                }
            }
        }
    }
}

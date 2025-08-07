@Library("jenkins-library@main")

import com.logicalclocks.jenkins.k8s.ImageBuilder

pipeline {
  agent { label 'local' }

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

                            # Remove all images matching the name (to save space)
                            docker images -q strimzi/image-builder | xargs -r docker rmi -f

                            # Build the image
                            docker build -t strimzi/image-builder:1.0 .

                            # Create container
                            docker create --name extract-container strimzi/image-builder:1.0

                            # Copy out the generated docker images
                            docker cp extract-container:/docker-images ./docker-images

                            # Remove container
                            docker rm -f extract-container
                        """

                        // variables for the Docker image
                        def strimzi_version = readFile("release.version").trim()
                        def kafka_version = "3.9.0"
                        def libs_version = "3.9.x"

                        // Create strimzi base image (no need to push it, it is used by other images)
                        sh """
                            docker build --build-arg strimzi_version=${strimzi_version} -t strimzi/base:latest ./docker-images/base
                        """

                        // Build the Docker image
                        withEnv([
                            "STRIMZI_VERSION=${strimzi_version}",
                            "KAFKA_VERSION=${kafka_version}",
                            "LIBS_VERSION=${libs_version}",
                            "KAFKA_DOCKER_TAG=${strimzi_version}-kafka-${kafka_version}"
                        ]) {
                            def builder = new ImageBuilder(this)
                            def m = readFile "${env.WORKSPACE}/build-manifest.json"
                            builder.run(m)
                        }
                    }
                }
            }
        }
    }
}

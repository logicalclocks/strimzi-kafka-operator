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
                            docker build -t strimzi/image-builder:1.0 .
                            docker create --name extract-container strimzi/image-builder:1.0
                            docker cp extract-container:/app/docker-images ./docker-images
                            docker rm extract-container
                        """

                        // variables for the Docker image
                        def version = readFile("release.version").trim()
                        def kafka_version = "3.9.0"
                        def libs_version = "3.9.x"

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

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
                            docker run --name extract-container strimzi/image-builder:1.0
                            docker cp extract-container:/app/docker-images ./docker-images
                            docker rm extract-container
                        """

                        // Build the Docker image using docker-images
                        sh '''
                            make docker_build
                        '''

                        def version = readFile("release.version").trim()
                        def builder = new ImageBuilder(this)

                        // Push the Docker image
                        builder.REGISTRIES.each { reg ->
                            // Authenticate to the registry
                            reg.auth()

                            // Get registryUrl
                            def fullImage = reg.buildImageName("dummy", "latest")
                            def registryUrl = fullImage.split('/')[0]

                            // Push the image
                            sh """
                                export DOCKER_REGISTRY=${registryUrl}
                                export DOCKER_ORG=strimzi
                                export DOCKER_TAG=${version}
                                make docker_push
                            """
                        }
                    }
                }
            }
        }
    }
}

@Library("jenkins-library@main")

import com.logicalclocks.jenkins.k8s.ImageBuilder

pipeline {
    agent {
        docker {
            image 'maven:3.8.5-openjdk-17-slim'
            args '--user=root -v $HOME/.m2:/root/.m2'
        }
    }
    stages {
        stage('Clone repository') {
            steps {
                checkout scm
            }
        }
        stage("Get kafka authorizer") {
            steps {
                // get and install kafka authorizer
                sh "curl -L -o hops-kafka-authorizer-4.0.0-SNAPSHOT.jar https://repo.hops.works/master/hops-kafka-authorizer/4.0.0-SNAPSHOT/hops-kafka-authorizer-4.0.0-SNAPSHOT.jar"
                sh "mvn install:install-file \
                    -Dfile=hops-kafka-authorizer-4.0.0-SNAPSHOT.jar \
                    -DgroupId=hops.io.kafka \
                    -DartifactId=hops-kafka-authorizer \
                    -Dversion=4.0.0-SNAPSHOT \
                    -Dpackaging=jar"
            }
        }
        stage('Get strimzi version') {
            steps {
                script {
                    def version = sh(
                        script: 'mvn -q -Dexec.executable=echo -Dexec.args=\'${project.version}\' --non-recursive exec:exec',
                        returnStdout: true
                    ).trim()
                    env.STRIMZI_VERSION = version
                }
            }
        }
        stage("Build strimzi") {
            steps {
                // Install dependencies
                sh '''
                    apt-get update && apt-get install -y make git zip
                '''

                // Install docker
                sh '''
                    curl -fsSL https://get.docker.com -o get-docker.sh
                    sh get-docker.sh
                '''

                // Install shellcheck for shell script linting
                sh '''
                    curl -L https://github.com/koalaman/shellcheck/releases/download/v0.9.0/shellcheck-v0.9.0.linux.x86_64.tar.xz | tar -xJ
                    cp shellcheck-v0.9.0/shellcheck /usr/local/bin/
                    chmod +x /usr/local/bin/shellcheck
                '''

                // Install yq for processing YAML files
                sh '''
                    curl -L https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_amd64 -o /usr/local/bin/yq
                    chmod +x /usr/local/bin/yq
                    yq --version
                '''

                // Install helm
                sh '''
                    curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz
                    tar -xzf helm.tar.gz
                    mv linux-amd64/helm /usr/local/bin/helm
                    chmod +x /usr/local/bin/helm
                '''

                // Java build
                sh '''
                    make MVN_ARGS='-DskipTests' java_install
                '''
            }
        }
        stage('Build and push images') {
            steps {
                script {
                    node('local') {
                        withCredentials([usernamePassword(credentialsId: 'a0770738-4ef3-4acc-a6ba-097ee6c85b44', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                            // Set the Kafka and libs versions
                            def kafka_version = "3.9.0"
                            def libs_version = "3.9.x"

                            // Build the Docker image
                            withEnv([
                                "STRIMZI_VERSION=${env.STRIMZI_VERSION}",
                                "KAFKA_VERSION=${kafka_version}",
                                "LIBS_VERSION=${libs_version}",
                                "KAFKA_DOCKER_TAG=${env.STRIMZI_VERSION}-kafka-${kafka_version}"
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
}
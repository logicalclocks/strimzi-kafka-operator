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
        stage("Build strimzi") {
            agent {
                docker {
                    image 'maven:3.8.5-openjdk-17-slim'
                    args '--user=root -v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                sh '''
                    rm -rf hops-kafka-authorizer
                    git clone --branch HWORKS-2215 --single-branch https://github.com/bubriks/hops-kafka-authorizer.git
                    cd hops-kafka-authorizer
                    mvn clean install
                '''

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

                // get kafka authorizer
                sh "curl -L -o /tmp/hops-kafka-authorizer.jar https://repo.hops.works/master/hops-kafka-authorizer/4.0.0-SNAPSHOT/hops-kafka-authorizer-4.0.0-SNAPSHOT.jar"

                // Java build
                sh '''
                    make MVN_ARGS='-DskipTests' java_install
                '''

                // Build the Docker image
                sh '''
                    make docker_build
                '''
            }
        }
        stage('Push images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'a0770738-4ef3-4acc-a6ba-097ee6c85b44', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                    script {
                        new ImageBuilder(this)

                        sh '''
                            docker tag strimzi/operator:latest dev5.devnet.hops.works:5043/ralfs_mini_registry/strimzi/operator:0.46.0
                            docker push dev5.devnet.hops.works:5043/ralfs_mini_registry/strimzi/operator:0.46.0
                        '''
                    }
                }
            }
        }
    }
}

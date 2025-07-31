@Library("jenkins-library@main")

import com.logicalclocks.jenkins.k8s.ImageBuilder

node("local") {
    stage('Clone repository') {
        checkout scm
    }

    stage('Build and push image(s)') {
        withCredentials([usernamePassword(credentialsId: 'a0770738-4ef3-4acc-a6ba-097ee6c85b44', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {

            docker.image('maven:3.8.5-openjdk-17-slim').inside('--user=root -v $HOME/.m2:/root/.m2') {
                // get and install kafka authorizer
                sh "curl -L -o hops-kafka-authorizer-4.0.0-SNAPSHOT.jar https://repo.hops.works/master/hops-kafka-authorizer/4.0.0-SNAPSHOT/hops-kafka-authorizer-4.0.0-SNAPSHOT.jar"
                sh "mvn install:install-file \
                    -Dfile=hops-kafka-authorizer-4.0.0-SNAPSHOT.jar \
                    -DgroupId=hops.io.kafka \
                    -DartifactId=hops-kafka-authorizer \
                    -Dversion=4.0.0-SNAPSHOT \
                    -Dpackaging=jar"

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

            // Get the Strimzi version from the pom.xml
            def strimzi_version = sh(
                script: 'mvn -q -Dexec.executable=echo -Dexec.args=\'${project.version}\' --non-recursive exec:exec',
                returnStdout: true
            ).trim()

            // Set the Kafka and libs versions
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
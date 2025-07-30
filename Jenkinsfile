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

                // Get the Strimzi version from the pom.xml
                sh "mvn -q -Dexec.executable=echo -Dexec.args='\${project.version}' --non-recursive exec:exec -l version.log"
                def strimzi_version = readFile("version.log").trim()

                // Install dependencies
                sh '''
                    apt-get update && apt-get install -y make git
                '''

                // Install docker
                sh '''
                    curl -fsSL https://get.docker.com -o get-docker.sh
                    sh get-docker.sh
                '''

                // Install yq for processing YAML files
                sh '''
                    curl -L https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_amd64 -o /usr/local/bin/yq
                    chmod +x /usr/local/bin/yq
                    yq --version
                '''

                // Java build
                sh '''
                    make MVN_ARGS='-DskipTests' java_build
                '''

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
}
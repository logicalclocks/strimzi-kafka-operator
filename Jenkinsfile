@Library("jenkins-library@main")

import com.logicalclocks.jenkins.k8s.ImageBuilder


node("local") {
    
    stage('Clone repository') {
      checkout scm
    }

    stage('Build and push image(s)') {
      withCredentials([usernamePassword(credentialsId: 'a0770738-4ef3-4acc-a6ba-097ee6c85b44', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
        sh "mvn -q -Dexec.executable=echo -Dexec.args='\${project.version}' --non-recursive exec:exec -l version.log"        
        strimzi_version = readFile "version.log"
        kafka_version = "3.6.0"
        withEnv(["VERSION=${strimzi_version.trim()}", "KAFKA_VERSION=${kafka_version}", "KAFKA_DOCKER_TAG=${strimzi_version.trim()}-kafka-${kafka_version}"]) {
           sh '''
                make MVN_ARGS='-DskipTests' java_build
            '''

            def builder = new ImageBuilder(this)

            m = readFile "${env.WORKSPACE}/build-manifest.json"
            builder.run(m)
        }
      }
    }
}
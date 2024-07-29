node("local") {
    
    stage('Clone repository') {
      checkout scm
    }

    stage('Build and push image(s)') {
      withCredentials([usernamePassword(credentialsId: 'a0770738-4ef3-4acc-a6ba-097ee6c85b44', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
        sh "mvn -q -Dexec.executable=echo -Dexec.args='\${project.version}' --non-recursive exec:exec -l version.log"        
        version = readFile "version.log"
        withEnv(["VERSION=${version.trim()}"]) {
           sh '''
                export DOCKER_ORG=strimzi
                export DOCKER_REGISTRY=docker.hops.works
                export DOCKER_TAG=${VERSION}

                make MVN_ARGS='-DskipTests' all
            '''
        }
      }
    }
}
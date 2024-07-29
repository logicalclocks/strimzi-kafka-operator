@Library("jenkins-library@main")

import com.logicalclocks.jenkins.k8s.ImageBuilder


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
                make MVN_ARGS='-DskipTests' java_build
            '''

            def builder = new ImageBuilder(this)

            m = readFile "${env.WORKSPACE}/build-manifest.json"
            builder.run(m)
        }
      }
    }
}
pipeline {
        environment {
                registry = "frost987/web-app"
                registryCredential = 'docker_system'
                dockerImage = ''
    }
    def remote = [:]
    	remote.name = 'master-node-uat'
	remote.host = '192.168.0.60'
	remote.user = 'administrator'
	remote.password = 'P@$$W0rd'
	remote.allowAnyHosts = true

  agent any

  stages {

    stage('Checkout Source') {
      steps {
        git url:'https://github.com/fizry/Projects.git', branch:'UAT'
      }
    }

      stage('Building our image') {
            steps {
                script {
                    dockerImage = sh "docker build --network=host -t $REGISTRY:latest ."
                }
            }
        }

        stage('Deploy our image') {
            steps {
                script {
                    docker.withRegistry( '', registryCredential ) {
                        sh "docker push $REGISTRY "
                    }
                }
            }
        }
       
	stage('Remote SSH') {
		sshCommand remote: remote, command: "ls -lrt"
       }
  }
}

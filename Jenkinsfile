pipeline {
    agent any

    environment {
        IMAGE_NAME = 'cicd-learning'
        IMAGE_TAG = 'latest'
        DOCKER_HUB_USER = 'sp3087'
    }

    stages {
        stage('Build') {
            steps {
                echo "Building image: ${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                echo "Build number: ${env.BUILD_NUMBER}"
                echo "Branch: ${env.GIT_BRANCH}"
                echo "Commit: ${env.GIT_COMMIT}"
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('SonarQube') {
            sh "mkdir -p ${WORKSPACE}/.sonar"
            sh """
                docker run --rm \
                    --network cicd-network \
                    --user root \
                    -e SONAR_HOST_URL=http://sonarqube:9000 \
                    -e SONAR_TOKEN=${SONAR_AUTH_TOKEN} \
                    -v ${WORKSPACE}:/usr/src \
                    sonarsource/sonar-scanner-cli \
                    -Dsonar.projectKey=cicd-learning \
                    -Dsonar.projectName=cicd-learning \
                    -Dsonar.sources=/usr/src \
                    -Dsonar.working.directory=/usr/src/.sonar
            """
        }
    }
}

        stage('Quality Gate') {
    steps {
        script {
            withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                def response = sh(
                    script: 'curl -s -u $SONAR_TOKEN: http://sonarqube:9000/api/qualitygates/project_status?projectKey=cicd-learning',
                    returnStdout: true
                ).trim()
                echo "Quality Gate response: ${response}"
                if (response.contains('"status":"ERROR"')) {
                    error 'Quality Gate FAILED!'
                } else {
                    echo 'Quality Gate PASSED!'
                }
            }
        }
    }
}

        stage('Test') {
            steps {
                echo 'Running container test...'
                sh 'docker run --name test-container ${IMAGE_NAME}:${IMAGE_TAG}'
                sh 'docker rm test-container'
                echo 'All tests passed!'
            }
        }

        stage('Push') {
            steps {
                echo 'Pushing to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh 'docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}'
                    sh 'docker push ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}'
                }
            }
        }

     stage('Deploy to Kubernetes') {
    steps {
        echo 'Deploying to Kubernetes...'
        sh 'kubectl set image deployment/cicd-learning cicd-learning=${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} --kubeconfig=/root/.kube/config'
        echo 'Kubernetes deployment triggered successfully!'
    }
}
    }

    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
            sh 'docker rm test-container || true'
        }
        always {
            echo "Build #${env.BUILD_NUMBER} complete"
            sh 'docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true'
        }
    }
}
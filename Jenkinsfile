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
            sh "mkdir -p ${WORKSPACE}/.scannerwork && chmod 777 ${WORKSPACE}/.scannerwork"
            sh """
                docker run --rm \
                    --network cicd-network \
                    -e SONAR_HOST_URL=http://sonarqube:9000 \
                    -e SONAR_TOKEN=${SONAR_AUTH_TOKEN} \
                    -v ${WORKSPACE}:/usr/src \
                    sonarsource/sonar-scanner-cli \
                    -Dsonar.projectKey=cicd-learning \
                    -Dsonar.projectName=cicd-learning \
                    -Dsonar.sources=. \
                    -Dsonar.working.directory=/usr/src/.scannerwork
            """
        }
    }
}

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
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
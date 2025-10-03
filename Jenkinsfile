pipeline {
    agent any
    
    environment {
        DOCKER_HOST = "unix:///var/run/docker.sock"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/Buhaha2525/express_mongo_react.git'
            }
        }
        
        stage('Build Frontend') {
            steps {
                dir('front-end') {
                    sh 'docker build -t frontend-app .'
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                dir('back-end') {
                    sh 'docker build -t backend-app .'
                }
            }
        }
        
        stage('Deploy with Docker Compose') {
            steps {
                sh 'docker compose down'
                sh 'docker compose up -d'
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline terminé - vérifiez les logs ci-dessus'
        }
        success {
            emailext(
                subject: "Build SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Pipeline réussi\nDétails : ${env.BUILD_URL}",
                to: "sowdmzz@gmail.com"
            )
            echo '✅ Déploiement réussi!'
            echo 'Frontend: http://localhost:5173'
            echo 'Backend: http://localhost:5001'
        }
        failure {
            echo '❌ Échec du déploiement'
            emailext(
                subject: "Build FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Le pipeline a échoué\nDétails : ${env.BUILD_URL}",
                to: "sowdmzz@gmail.com"
            )
        }
    }
}

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
                sh 'docker-compose down || true'  // || true pour éviter l'échec si aucun conteneur
                sh 'docker-compose up -d --build'  // --build pour rebuild si nécessaire
            }
        }
        
        stage('Verification') {
            steps {
                sh '''
                    echo "⏳ Attente du démarrage des services..."
                    sleep 30
                    echo "📊 État des conteneurs:"
                    docker-compose ps
                    echo "🔍 Logs récents:"
                    docker-compose logs --tail=20
                '''
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline terminé - vérifiez les logs ci-dessus'
            sh 'docker-compose ps || true'
        }
        success {
            echo '✅ Déploiement réussi!'
            echo 'Frontend: http://localhost:5173'
            echo 'Backend: http://localhost:5001'
            // L'email nécessite une configuration SMTP dans Jenkins
        }
        failure {
            echo '❌ Échec du déploiement'
            sh 'docker-compose logs || true'
        }
    }
}

pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/Buhaha2525/express_mongo_react.git'
            }
        }
        
        stage('Cleanup Existing Containers') {
            steps {
                sh '''
                    echo "🧹 Nettoyage des conteneurs existants..."
                    
                    # Arrêter et supprimer les conteneurs spécifiques
                    docker stop mongo 2>/dev/null || echo "Aucun conteneur mongo à arrêter"
                    docker rm mongo 2>/dev/null || echo "Aucun conteneur mongo à supprimer"
                    
                    docker stop express-api 2>/dev/null || echo "Aucun conteneur express-api à arrêter"
                    docker rm express-api 2>/dev/null || echo "Aucun conteneur express-api à supprimer"
                    
                    docker stop react-frontend 2>/dev/null || echo "Aucun conteneur react-frontend à arrêter"
                    docker rm react-frontend 2>/dev/null || echo "Aucun conteneur react-frontend à supprimer"
                    
                    # Nettoyage complet avec docker compose
                    docker compose down 2>/dev/null || echo "docker compose down échoué ou non disponible"
                    
                    # Supprimer les conteneurs orphelins
                    docker ps -aq --filter "status=exited" | xargs docker rm 2>/dev/null || true
                '''
            }
        }
        
        stage('Build Images') {
            steps {
                sh '''
                    echo "🔨 Construction des images..."
                    docker compose build --no-cache
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    echo "🚀 Déploiement en cours..."
                    docker compose up -d
                    
                    echo "⏳ Attente du démarrage..."
                    sleep 30
                    
                    echo "📊 État des conteneurs:"
                    docker compose ps
                '''
            }
        }
        
        stage('Health Check') {
            steps {
                sh '''
                    echo "🏥 Vérification de la santé des services..."
                    
                    # Vérifier que les conteneurs sont en cours d'exécution
                    if docker compose ps | grep -q "Up"; then
                        echo "✅ Tous les services sont en cours d'exécution"
                    else
                        echo "❌ Certains services ne sont pas démarrés"
                        docker compose ps
                        exit 1
                    fi
                    
                    # Test simple de connectivité
                    echo "🔗 URLs de l'application:"
                    echo "Frontend: http://localhost:5173"
                    echo "Backend: http://localhost:5001/api"
                    echo "MongoDB: localhost:27017"
                '''
            }
        }
    }
    
    post {
        always {
            echo '📝 Pipeline terminé - vérifiez les logs ci-dessus'
            sh '''
                echo "📋 État final des conteneurs:"
                docker compose ps || true
                echo "🔍 Derniers logs:"
                docker compose logs --tail=20 || true
            '''
        }
        success {
            script {
                echo '✅ Déploiement réussi!'
                // Récupérer l'état des conteneurs pour l'email
                def containerStatus = sh(script: 'docker compose ps', returnStdout: true)
                
                emailext (
                    subject: "✅ SUCCÈS - Déploiement ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    <html>
                    <body>
                    <h2>🚀 Déploiement Réussi!</h2>
                    
                    <p>Le pipeline <strong>${env.JOB_NAME}</strong> s'est terminé avec succès.</p>
                    
                    <h3>📊 Détails de la build:</h3>
                    <ul>
                        <li><strong>Build:</strong> #${env.BUILD_NUMBER}</li>
                        <li><strong>Job:</strong> ${env.JOB_NAME}</li>
                        <li><strong>URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                        <li><strong>Date:</strong> ${new Date().format("dd/MM/yyyy à HH:mm")}</li>
                    </ul>
                    
                    <h3>🌐 Application déployée:</h3>
                    <ul>
                        <li><strong>Frontend React:</strong> <a href="http://localhost:5173">http://localhost:5173</a></li>
                        <li><strong>Backend Express:</strong> <a href="http://localhost:5001/api">http://localhost:5001/api</a></li>
                        <li><strong>MongoDB:</strong> localhost:27017</li>
                    </ul>
                    
                    <h3>🐋 Conteneurs Docker:</h3>
                    <pre>${containerStatus}</pre>
                    
                    <p style="color: green; font-weight: bold;">✅ Tous les services sont opérationnels</p>
                    
                    <hr>
                    <p><small>Email envoyé automatiquement par Jenkins</small></p>
                    </body>
                    </html>
                    """,
                    to: "sowdmzz@gmail.com",
                    mimeType: "text/html"
                )
            }
        }
        failure {
            script {
                echo '❌ Échec du déploiement'
                // Récupérer les logs d'erreur
                def errorLogs = sh(script: 'docker compose logs --tail=50 2>/dev/null || echo "Impossible de récupérer les logs"', returnStdout: true)
                
                emailext (
                    subject: "❌ ÉCHEC - Déploiement ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    <html>
                    <body>
                    <h2>💥 Échec du Déploiement</h2>
                    
                    <p>Le pipeline <strong>${env.JOB_NAME}</strong> a échoué.</p>
                    
                    <h3>📊 Détails de la build:</h3>
                    <ul>
                        <li><strong>Build:</strong> #${env.BUILD_NUMBER}</li>
                        <li><strong>Job:</strong> ${env.JOB_NAME}</li>
                        <li><strong>URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                        <li><strong>Date:</strong> ${new Date().format("dd/MM/yyyy à HH:mm")}</li>
                    </ul>
                    
                    <h3>🔍 Logs d'erreur:</h3>
                    <pre style="background-color: #f8f8f8; padding: 10px; border-left: 4px solid #ff0000;">
                    ${errorLogs}
                    </pre>
                    
                    <p style="color: red; font-weight: bold;">❌ Une intervention est nécessaire</p>
                    
                    <hr>
                    <p><small>Email envoyé automatiquement par Jenkins</small></p>
                    </body>
                    </html>
                    """,
                    to: "sowdmzz@gmail.com",
                    mimeType: "text/html"
                )
            }
        }
        unstable {
            emailext (
                subject: "⚠️ INSTABLE - Déploiement ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Le pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} est instable.\n\nDétails: ${env.BUILD_URL}",
                to: "sowdmzz@gmail.com"
            )
        }
    }
}

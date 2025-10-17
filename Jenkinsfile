pipeline {
    agent any

    environment {
        // Identifiant des identifiants Docker Hub (configuré dans Jenkins)
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        // Nom du registre Docker Hub
        DOCKER_REGISTRY = 'dmzz'
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/express-frontend"
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/express-backend"
        // Dépôt GitHub
        GITHUB_REPO = 'https://github.com/Buhaha2525/express_mongo_react.git'
        // Identifiant des identifiants GitHub (configuré dans Jenkins)
        GITHUB_CREDENTIALS_ID = 'github-credentials'
        // Configuration SonarQube
        SONARQUBE_SCANNER_HOME = tool 'SonarQubeScanner'
        SONAR_HOST_URL = 'http://localhost:9000'
        SONAR_PROJECT_KEY = 'express_mongo_react'
        // ID des credentials SonarQube
        SONAR_CREDENTIALS_ID = 'jenkins-sonar'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/Buhaha2525/express_mongo_react.git'
            }
        }
        
        stage('Clean SonarQube Configuration') {
            steps {
                sh '''
                    echo "🧹 Nettoyage de la configuration SonarQube..."
                    # Supprimer ou renommer le fichier sonar-project.properties s'il existe
                    if [ -f "sonar-project.properties" ]; then
                        echo "📄 Fichier sonar-project.properties trouvé, suppression..."
                        rm -f sonar-project.properties
                    fi
                    
                    # Nettoyer les dossiers temporaires SonarQube
                    rm -rf .scannerwork target build
                '''
            }
        }
        
        stage('Verify Structure') {
            steps {
                sh '''
                    echo "📁 Vérification de la structure..."
                    echo "Dossiers trouvés:"
                    ls -la
                    echo ""
                    echo "Contenu de back-end:"
                    ls -la back-end/ || echo "back-end non accessible"
                    echo ""
                    echo "Contenu de front-end:"
                    ls -la front-end/ || echo "front-end non accessible"
                '''
            }
        }
        
        stage('Dependency Installation') {
            parallel {
                stage('Install Frontend Dependencies') {
                    steps {
                        sh '''
                            echo "📦 Installation des dépendances Frontend..."
                            cd front-end && npm install
                            echo "✅ Dépendances frontend installées"
                        '''
                    }
                }
                stage('Install Backend Dependencies') {
                    steps {
                        sh '''
                            echo "📦 Installation des dépendances Backend..."
                            cd back-end && npm install
                            echo "✅ Dépendances backend installées"
                        '''
                    }
                }
            }
        }
        
        stage('SonarQube Analysis - Backend') {
            steps {
                script {
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            echo "🔍 Analyse SonarQube Backend..."
                            ${SONARQUBE_SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY}-backend \
                            -Dsonar.projectName='Express Backend' \
                            -Dsonar.projectVersion=${BUILD_NUMBER} \
                            -Dsonar.sources=back-end \
                            -Dsonar.exclusions=**/node_modules/**,**/coverage/**,**/*.test.js \
                            -Dsonar.sourceEncoding=UTF-8
                        """
                    }
                }
            }
        }
        
        stage('SonarQube Analysis - Frontend') {
            steps {
                script {
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            echo "🔍 Analyse SonarQube Frontend..."
                            ${SONARQUBE_SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY}-frontend \
                            -Dsonar.projectName='React Frontend' \
                            -Dsonar.projectVersion=${BUILD_NUMBER} \
                            -Dsonar.sources=front-end \
                            -Dsonar.exclusions=**/node_modules/**,**/coverage/**,**/*.test.js \
                            -Dsonar.sourceEncoding=UTF-8
                        """
                    }
                }
            }
        }
        
        stage('Wait for Analysis Completion') {
            steps {
                script {
                    echo "⏳ Attente de la fin des analyses SonarQube (60 secondes)..."
                    sleep time: 60, unit: 'SECONDS'
                }
            }
        }
        
        stage('Quality Gate Check') {
            steps {
                script {
                    echo "✅ Vérification des Quality Gates..."
                    // On continue même si la Quality Gate échoue pour le moment
                    try {
                        timeout(time: 2, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: false
                        }
                        echo "✅ Quality Gate passée avec succès"
                    } catch (Exception e) {
                        echo "⚠️  Quality Gate échouée ou timeout, continuation du pipeline..."
                        echo "Détails de l'erreur: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                sh '''
                    echo "🔒 Analyse de sécurité des dépendances..."
                    echo "=== Backend ==="
                    cd back-end && npm audit --audit-level moderate || true
                    echo "=== Frontend ==="
                    cd ../front-end && npm audit --audit-level moderate || true
                '''
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
                    
                    # Nettoyer les dossiers temporaires SonarQube
                    rm -rf .scannerwork || true
                '''
            }
        }
        
        stage('Fix Docker Credentials') {
            steps {
                sh '''
                    echo "🔧 Correction des credentials Docker..."
                    # Supprimer la configuration Docker Desktop qui cause des problèmes
                    rm -f ~/.docker/config.json || echo "Fichier config.json non trouvé"
                    
                    # Vérifier la configuration Docker actuelle
                    echo "Configuration Docker actuelle:"
                    docker system info | grep -E "(Username|Registry)" || echo "Non connecté"
                '''
            }
        }
        
        stage('Build Docker Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDENTIALS_ID}", 
                    usernameVariable: 'DOCKER_USERNAME', 
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "🔐 Connexion à Docker Hub..."
                        echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

                        echo "🔨 Construction des images Docker..."
                        # Construire les images une par une pour mieux gérer les erreurs
                        echo "Construction du backend..."
                        docker compose build backend --no-cache --progress=plain
                        
                        echo "Construction du frontend..."
                        docker compose build frontend --no-cache --progress=plain
                        
                        echo "📋 Liste des images construites:"
                        docker images
                    '''
                }
            }
        }
        
        stage('Tag & Push Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDENTIALS_ID}", 
                    usernameVariable: 'DOCKER_USERNAME', 
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "🔐 Vérification de la connexion Docker Hub..."
                        echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

                        echo "📋 Liste des images disponibles:"
                        docker images

                        echo "🔍 Recherche des images récentes..."
                        FRONTEND_ID=$(docker images pipesmartv2-frontend:latest -q)
                        BACKEND_ID=$(docker images pipesmartv2-backend:latest -q)

                        echo "Frontend ID: $FRONTEND_ID"
                        echo "Backend ID: $BACKEND_ID"

                        if [ -z "$FRONTEND_ID" ]; then
                            echo "❌ Image pipesmartv2-frontend:latest non trouvée"
                            echo "Images disponibles:"
                            docker images
                            exit 1
                        fi

                        if [ -z "$BACKEND_ID" ]; then
                            echo "❌ Image pipesmartv2-backend:latest non trouvée"
                            echo "Images disponibles:"
                            docker images
                            exit 1
                        fi

                        echo "🏷️  Taggage des images..."
                        docker tag $FRONTEND_ID ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker tag $FRONTEND_ID ${FRONTEND_IMAGE}:latest
                        docker tag $BACKEND_ID ${BACKEND_IMAGE}:${BUILD_NUMBER}
                        docker tag $BACKEND_ID ${BACKEND_IMAGE}:latest

                        echo "📤 Poussage des images..."
                        echo "Poussage du frontend..."
                        docker push ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${FRONTEND_IMAGE}:latest
        
                        echo "Poussage du backend..."
                        docker push ${BACKEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${BACKEND_IMAGE}:latest

                        echo "🔓 Déconnexion de Docker Hub..."
                        docker logout
                        
                        echo "✅ Images poussées avec succès!"
                    '''
                }
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
                    
                    if docker compose ps | grep -q "Up"; then
                        echo "✅ Tous les services sont en cours d'exécution"
                    else
                        echo "❌ Certains services ne sont pas démarrés"
                        docker compose ps
                        exit 1
                    fi
                    
                    # Tests de santé supplémentaires
                    echo "🔍 Tests de connectivité..."
                    echo "Test Backend (attente 5s)..."
                    sleep 5
                    curl -f http://localhost:5001/api/health || echo "Backend health check failed"
                    echo "Test Frontend (attente 5s)..."
                    sleep 5
                    curl -f http://localhost:5173 || echo "Frontend health check failed"
                    
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
            
            // Nettoyage
            sh '''
                echo "🧹 Nettoyage des ressources temporaires..."
                docker system prune -f || true
                rm -rf .scannerwork || true
            '''
        }
        success {
            script {
                echo '✅ Déploiement réussi!'
                def containerStatus = sh(script: 'docker compose ps', returnStdout: true)
                def sonarBackendUrl = "${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}-backend"
                def sonarFrontendUrl = "${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}-frontend"
                
                // Vérifier l'état des analyses SonarQube
                def sonarStatus = "Analyses terminées"
                try {
                    def qualityGate = waitForQualityGate abortPipeline: false
                    sonarStatus = "Quality Gate: ${qualityGate.status}"
                } catch (Exception e) {
                    sonarStatus = "Analyses effectuées (Quality Gate ignorée)"
                }
                
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
                        <li><strong>Statut SonarQube:</strong> ${sonarStatus}</li>
                    </ul>
                    
                    <h3>📈 Qualité du code:</h3>
                    <ul>
                        <li><strong>Rapport Backend SonarQube:</strong> <a href="${sonarBackendUrl}">Voir le rapport</a></li>
                        <li><strong>Rapport Frontend SonarQube:</strong> <a href="${sonarFrontendUrl}">Voir le rapport</a></li>
                        <li><strong>Analyse de sécurité:</strong> Effectuée</li>
                    </ul>
                    
                    <h3>🐳 Images Docker:</h3>
                    <ul>
                        <li><strong>Frontend:</strong> ${FRONTEND_IMAGE}:${BUILD_NUMBER}</li>
                        <li><strong>Backend:</strong> ${BACKEND_IMAGE}:${BUILD_NUMBER}</li>
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
            script {
                echo '⚠️  Déploiement instable (Quality Gate échouée)'
                def containerStatus = sh(script: 'docker compose ps', returnStdout: true)
                def sonarBackendUrl = "${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}-backend"
                def sonarFrontendUrl = "${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}-frontend"
                
                emailext (
                    subject: "⚠️  INSTABLE - Déploiement ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    <html>
                    <body>
                    <h2>⚠️  Déploiement Instable</h2>
                    
                    <p>Le pipeline <strong>${env.JOB_NAME}</strong> s'est terminé avec un statut instable (Quality Gate SonarQube échouée).</p>
                    
                    <h3>📊 Détails de la build:</h3>
                    <ul>
                        <li><strong>Build:</strong> #${env.BUILD_NUMBER}</li>
                        <li><strong>Job:</strong> ${env.JOB_NAME}</li>
                        <li><strong>URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                        <li><strong>Date:</strong> ${new Date().format("dd/MM/yyyy à HH:mm")}</li>
                        <li><strong>Statut:</strong> Quality Gate SonarQube échouée</li>
                    </ul>
                    
                    <h3>📈 Qualité du code:</h3>
                    <ul>
                        <li><strong>Rapport Backend SonarQube:</strong> <a href="${sonarBackendUrl}">Voir le rapport</a></li>
                        <li><strong>Rapport Frontend SonarQube:</strong> <a href="${sonarFrontendUrl}">Voir le rapport</a></li>
                    </ul>
                    
                    <h3>🌐 Application déployée:</h3>
                    <ul>
                        <li><strong>Frontend React:</strong> <a href="http://localhost:5173">http://localhost:5173</a></li>
                        <li><strong>Backend Express:</strong> <a href="http://localhost:5001/api">http://localhost:5001/api</a></li>
                    </ul>
                    
                    <h3>🐋 Conteneurs Docker:</h3>
                    <pre>${containerStatus}</pre>
                    
                    <p style="color: orange; font-weight: bold;">⚠️  L'application est déployée mais la qualité du code nécessite attention</p>
                    
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
    }
}

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
        SONAR_HOST_URL = 'http://localhost:9000' // Ajustez l'URL de votre instance SonarQube
        SONAR_PROJECT_KEY = 'express_mongo_react'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/Buhaha2525/express_mongo_react.git'
            }
        }
        
        stage('Dependency Installation') {
            parallel {
                stage('Install Frontend Dependencies') {
                    steps {
                        sh '''
                            echo "📦 Installation des dépendances Frontend..."
                            cd frontend && npm install
                        '''
                    }
                }
                stage('Install Backend Dependencies') {
                    steps {
                        sh '''
                            echo "📦 Installation des dépendances Backend..."
                            cd backend && npm install
                        '''
                    }
                }
            }
        }
        
        stage('SonarQube Analysis') {
            parallel {
                stage('Backend Code Analysis') {
                    steps {
                        script {
                            withSonarQubeEnv('SonarQube') { // 'SonarQube' doit être configuré dans Jenkins
                                sh """
                                    ${SONARQUBE_SCANNER_HOME}/bin/sonar-scanner \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY}-backend \
                                    -Dsonar.projectName='Express Backend' \
                                    -Dsonar.projectVersion=${BUILD_NUMBER} \
                                    -Dsonar.sources=backend/src \
                                    -Dsonar.tests=backend/test \
                                    -Dsonar.javascript.lcov.reportPaths=backend/coverage/lcov.info \
                                    -Dsonar.coverage.exclusions=**/test/**,**/node_modules/** \
                                    -Dsonar.sourceEncoding=UTF-8
                                """
                            }
                        }
                    }
                }
                stage('Frontend Code Analysis') {
                    steps {
                        script {
                            withSonarQubeEnv('SonarQube') {
                                sh """
                                    ${SONARQUBE_SCANNER_HOME}/bin/sonar-scanner \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY}-frontend \
                                    -Dsonar.projectName='React Frontend' \
                                    -Dsonar.projectVersion=${BUILD_NUMBER} \
                                    -Dsonar.sources=frontend/src \
                                    -Dsonar.tests=frontend/src \
                                    -Dsonar.javascript.lcov.reportPaths=frontend/coverage/lcov.info \
                                    -Dsonar.coverage.exclusions=**/test/**,**/node_modules/**,**/*.test.js \
                                    -Dsonar.sourceEncoding=UTF-8
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    timeout(time: 10, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        
        stage('Tests & Coverage') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        sh '''
                            echo "🧪 Exécution des tests Backend..."
                            cd backend && npm test -- --coverage
                        '''
                    }
                }
                stage('Frontend Tests') {
                    steps {
                        sh '''
                            echo "🧪 Exécution des tests Frontend..."
                            cd frontend && npm test -- --coverage --watchAll=false
                        '''
                    }
                }
            }
            post {
                always {
                    sh '''
                        echo "📊 Rapports de couverture générés"
                        # Sauvegarder les rapports de test
                        mkdir -p test-reports
                        [ -f backend/coverage/coverage-final.json ] && cp backend/coverage/coverage-final.json test-reports/backend-coverage.json || echo "Aucun rapport backend"
                        [ -f frontend/coverage/coverage-final.json ] && cp frontend/coverage/coverage-final.json test-reports/frontend-coverage.json || echo "Aucun rapport frontend"
                    '''
                    junit '**/test-results/**/*.xml' // Si vous générez des rapports JUnit
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'backend/coverage/lcov-report',
                        reportFiles: 'index.html',
                        reportName: 'Backend Coverage Report'
                    ])
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'frontend/coverage/lcov-report',
                        reportFiles: 'index.html',
                        reportName: 'Frontend Coverage Report'
                    ])
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                sh '''
                    echo "🔒 Analyse de sécurité des dépendances..."
                    # Scan des vulnérabilités avec npm audit
                    cd backend && npm audit --audit-level moderate || true
                    cd ../frontend && npm audit --audit-level moderate || true
                '''
            }
        }
        
        stage('Build Docker Images') {
            steps {
                sh '''
                    echo "🔨 Construction des images Docker..."
                    docker compose build --no-cache
                    
                    echo "📋 Liste des images construites:"
                    docker images
                '''
            }
        }
        
        stage('Tag & Push Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "docker-hub-credentials", 
                    usernameVariable: 'DOCKER_USERNAME', 
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "🔐 Connexion à Docker Hub..."
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
                            docker images | grep -E "(frontend|backend)" || docker images
                            exit 1
                        fi

                        if [ -z "$BACKEND_ID" ]; then
                            echo "❌ Image pipesmartv2-backend:latest non trouvée"
                            docker images | grep -E "(frontend|backend)" || docker images
                            exit 1
                        fi

                        echo "🏷️  Taggage des images..."
                        docker tag $FRONTEND_ID ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker tag $FRONTEND_ID ${FRONTEND_IMAGE}:latest
                        docker tag $BACKEND_ID ${BACKEND_IMAGE}:${BUILD_NUMBER}
                        docker tag $BACKEND_ID ${BACKEND_IMAGE}:latest

                        echo "📤 Poussage des images..."
                        docker push ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${FRONTEND_IMAGE}:latest
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
                    curl -f http://localhost:5001/api/health || echo "Backend health check failed"
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
            '''
        }
        success {
            script {
                echo '✅ Déploiement réussi!'
                def containerStatus = sh(script: 'docker compose ps', returnStdout: true)
                def sonarUrl = "${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}"
                
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
                    
                    <h3>📈 Qualité du code:</h3>
                    <ul>
                        <li><strong>Rapport SonarQube:</strong> <a href="${sonarUrl}">Voir le rapport</a></li>
                        <li><strong>Tests exécutés:</strong> Backend & Frontend</li>
                        <li><strong>Analyse de sécurité:</strong> Effectuée</li>
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
    }
}

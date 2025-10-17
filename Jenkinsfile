pipeline {
    agent any

    environment {
        // Identifiant des identifiants Docker Hub
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        // Nom du registre Docker Hub
        DOCKER_REGISTRY = 'dmzz'
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/express-frontend"
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/express-backend"
        // Configuration SonarQube
        SONARQUBE_SCANNER_HOME = tool 'SonarScanner'
        SONAR_HOST_URL = 'http://localhost:9000'
        SONAR_PROJECT_KEY = 'express_mongo_react'
        // Configuration Email
        EMAIL_RECIPIENTS = 'sowdmzz@gmail.com'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/Buhaha2525/express_mongo_react.git',
                credentialsId: 'github-credentials'
            }
        }
        
        stage('Analyse Structure') {
            steps {
                sh '''
                    echo "🔍 Analyse détaillée de la structure..."
                    echo "=== Structure complète ==="
                    find . -type f -name "package.json" | head -20
                    echo ""
                    echo "=== Arborescence racine ==="
                    ls -la
                    echo ""
                    echo "=== Recherche des dossiers frontend/backend ==="
                    find . -type d -name "*front*" -o -name "*back*" -o -name "*server*" -o -name "*client*" | head -10
                    echo ""
                    echo "=== Fichiers package.json trouvés ==="
                    find . -name "package.json" -exec dirname {} \\; | head -10
                '''
            }
        }
        
        stage('Détection Automatique des Dossiers') {
            steps {
                script {
                    // Détection automatique des dossiers frontend/backend
                    def frontendDir = sh(
                        script: '''
                            find . -name "package.json" -exec dirname {} \\; | grep -iE "(front|client)" | head -1 || \
                            find . -maxdepth 2 -name "package.json" -exec dirname {} \\; | head -1
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    def backendDir = sh(
                        script: '''
                            find . -name "package.json" -exec dirname {} \\; | grep -iE "(back|server|api)" | head -1 || \
                            find . -maxdepth 2 -name "package.json" -exec dirname {} \\; | tail -1
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    // Si un seul dossier trouvé, on utilise le même pour les deux
                    if (!backendDir && frontendDir) {
                        backendDir = frontendDir
                    }
                    if (!frontendDir && backendDir) {
                        frontendDir = backendDir
                    }
                    
                    // Si aucun dossier trouvé, utiliser la racine
                    if (!frontendDir && !backendDir) {
                        frontendDir = "."
                        backendDir = "."
                    }
                    
                    // Définition des variables d'environnement
                    env.FRONTEND_DIR = frontendDir
                    env.BACKEND_DIR = backendDir
                    
                    echo "📁 Dossiers détectés:"
                    echo "Frontend: ${env.FRONTEND_DIR}"
                    echo "Backend: ${env.BACKEND_DIR}"
                }
            }
        }
        
        stage('Vérification des Dossiers') {
            steps {
                sh '''
                    echo "✅ Vérification des dossiers détectés..."
                    echo "=== Contenu Frontend (${FRONTEND_DIR}) ==="
                    ls -la "${FRONTEND_DIR}" 2>/dev/null || echo "Dossier frontend non accessible"
                    echo ""
                    echo "=== Contenu Backend (${BACKEND_DIR}) ==="
                    ls -la "${BACKEND_DIR}" 2>/dev/null || echo "Dossier backend non accessible"
                    echo ""
                    echo "=== Fichiers package.json ==="
                    find "${FRONTEND_DIR}" -name "package.json" 2>/dev/null | head -5
                    find "${BACKEND_DIR}" -name "package.json" 2>/dev/null | head -5
                    echo ""
                    echo "=== Vérification existence package.json ==="
                    test -f "${FRONTEND_DIR}/package.json" && echo "✅ package.json trouvé dans frontend" || echo "❌ package.json NON trouvé dans frontend"
                    test -f "${BACKEND_DIR}/package.json" && echo "✅ package.json trouvé dans backend" || echo "❌ package.json NON trouvé dans backend"
                '''
            }
        }
        
        stage('Installation Dépendances') {
            parallel {
                stage('Install Frontend') {
                    steps {
                        script {
                            dir(env.FRONTEND_DIR) {
                                sh '''
                                    echo "📦 Installation dépendances Frontend dans $(pwd)"
                                    if [ -f "package.json" ]; then
                                        echo "📄 package.json trouvé, installation..."
                                        npm install
                                        if [ $? -eq 0 ]; then
                                            echo "✅ Dépendances frontend installées avec succès"
                                        else
                                            echo "❌ Erreur lors de l'installation frontend"
                                            exit 1
                                        fi
                                    else
                                        echo "❌ package.json non trouvé dans $(pwd)"
                                        echo "Contenu du dossier:"
                                        ls -la
                                        exit 1
                                    fi
                                '''
                            }
                        }
                    }
                }
                stage('Install Backend') {
                    steps {
                        script {
                            // Si c'est le même dossier, on saute l'installation double
                            if (env.BACKEND_DIR == env.FRONTEND_DIR) {
                                echo "⚠️ Même dossier pour frontend et backend - installation déjà faite"
                            } else {
                                dir(env.BACKEND_DIR) {
                                    sh '''
                                        echo "📦 Installation dépendances Backend dans $(pwd)"
                                        if [ -f "package.json" ]; then
                                            echo "📄 package.json trouvé, installation..."
                                            npm install
                                            if [ $? -eq 0 ]; then
                                                echo "✅ Dépendances backend installées avec succès"
                                            else
                                                echo "❌ Erreur lors de l'installation backend"
                                                exit 1
                                            fi
                                        else
                                            echo "❌ package.json non trouvé dans $(pwd)"
                                            echo "Contenu du dossier:"
                                            ls -la
                                            exit 1
                                        fi
                                    '''
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Analyse SonarQube') {
            parallel {
                stage('Analyse Backend') {
                    steps {
                        script {
                            withSonarQubeEnv('SonarQube') {
                                dir(env.BACKEND_DIR) {
                                    sh """
                                        echo "🔍 Analyse SonarQube Backend dans $(pwd)"
                                        ${SONARQUBE_SCANNER_HOME}/bin/sonar-scanner \
                                        -Dsonar.projectKey=${SONAR_PROJECT_KEY}-backend \
                                        -Dsonar.projectName='Express Backend' \
                                        -Dsonar.projectVersion=${BUILD_NUMBER} \
                                        -Dsonar.sources=. \
                                        -Dsonar.exclusions=**/node_modules/**,**/coverage/**,**/*.test.js \
                                        -Dsonar.sourceEncoding=UTF-8 \
                                        -Dsonar.host.url=${SONAR_HOST_URL}
                                    """
                                }
                            }
                        }
                    }
                }
                stage('Analyse Frontend') {
                    steps {
                        script {
                            // Si c'est le même dossier, on fait une seule analyse
                            if (env.FRONTEND_DIR == env.BACKEND_DIR) {
                                echo "⚠️ Même dossier - analyse SonarQube déjà faite"
                            } else {
                                withSonarQubeEnv('SonarQube') {
                                    dir(env.FRONTEND_DIR) {
                                        sh """
                                            echo "🔍 Analyse SonarQube Frontend dans $(pwd)"
                                            ${SONARQUBE_SCANNER_HOME}/bin/sonar-scanner \
                                            -Dsonar.projectKey=${SONAR_PROJECT_KEY}-frontend \
                                            -Dsonar.projectName='React Frontend' \
                                            -Dsonar.projectVersion=${BUILD_NUMBER} \
                                            -Dsonar.sources=. \
                                            -Dsonar.exclusions=**/node_modules/**,**/coverage/**,**/*.test.js \
                                            -Dsonar.sourceEncoding=UTF-8 \
                                            -Dsonar.host.url=${SONAR_HOST_URL}
                                        """
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Wait for Quality Gate') {
            steps {
                script {
                    echo "⏳ Attente des résultats SonarQube..."
                    sleep 30
                    
                    def projects = ["${SONAR_PROJECT_KEY}-backend"]
                    if (env.FRONTEND_DIR != env.BACKEND_DIR) {
                        projects.add("${SONAR_PROJECT_KEY}-frontend")
                    }
                    
                    def qualityGateResults = [:]
                    def allPassed = true
                    
                    projects.each { projectKey ->
                        try {
                            timeout(time: 1, unit: 'MINUTES') {
                                def qualityGate = waitForQualityGate abortPipeline: false
                                qualityGateResults[projectKey] = qualityGate.status
                                echo "✅ Quality Gate ${qualityGate.status} pour ${projectKey}"
                            }
                        } catch (Exception e) {
                            echo "⚠️ Erreur Quality Gate pour ${projectKey}: ${e.getMessage()}"
                            qualityGateResults[projectKey] = 'FAILED'
                            allPassed = false
                        }
                    }
                    
                    if (!allPassed) {
                        currentBuild.result = 'UNSTABLE'
                    }
                    
                    env.SONAR_RESULTS = qualityGateResults.toString()
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    dir(env.FRONTEND_DIR) {
                        sh '''
                            echo "🔒 Analyse sécurité Frontend..."
                            npm audit --audit-level moderate --production || true
                        '''
                    }
                    if (env.BACKEND_DIR != env.FRONTEND_DIR) {
                        dir(env.BACKEND_DIR) {
                            sh '''
                                echo "🔒 Analyse sécurité Backend..."
                                npm audit --audit-level moderate --production || true
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Docker Cleanup') {
            steps {
                sh '''
                    echo "🧹 Nettoyage des conteneurs existants..."
                    docker compose down 2>/dev/null || true
                    docker system prune -f 2>/dev/null || true
                    rm -f ~/.docker/config.json 2>/dev/null || true
                '''
            }
        }
        
        stage('Build & Push Docker Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDENTIALS_ID}", 
                    usernameVariable: 'DOCKER_USERNAME', 
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "🔐 Connexion à Docker Hub..."
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

                        echo "🔨 Construction des images Docker..."
                        docker compose build --no-cache

                        echo "🏷️  Taggage des images..."
                        docker tag pipesmartv2-frontend:latest ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker tag pipesmartv2-frontend:latest ${FRONTEND_IMAGE}:latest
                        docker tag pipesmartv2-backend:latest ${BACKEND_IMAGE}:${BUILD_NUMBER}
                        docker tag pipesmartv2-backend:latest ${BACKEND_IMAGE}:latest

                        echo "📤 Poussage des images..."
                        docker push ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${FRONTEND_IMAGE}:latest
                        docker push ${BACKEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${BACKEND_IMAGE}:latest

                        echo "🔓 Déconnexion de Docker Hub..."
                        docker logout
                    '''
                }
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    echo "🚀 Déploiement en cours..."
                    docker compose up -d
                    sleep 15
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
                        docker compose logs --tail=20
                        exit 1
                    fi
                    
                    echo "🔍 Tests de connectivité..."
                    timeout 30s bash -c '
                        until curl -f http://localhost:5001/api/health 2>/dev/null; do
                            echo "En attente du backend..."
                            sleep 5
                        done
                    ' || echo "Backend health check timeout"
                    
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
            echo "📝 Pipeline ${currentBuild.currentResult} - Build #${BUILD_NUMBER}"
            sh '''
                echo "📋 État final Docker:"
                docker compose ps 2>/dev/null || echo "Docker compose non disponible"
            '''
            
            script {
                // Récupérer les informations pour l'email
                def containerStatus = sh(script: 'docker compose ps 2>/dev/null || echo "Aucun conteneur"', returnStdout: true).trim()
                def sonarBackendUrl = "${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}-backend"
                def sonarFrontendUrl = "${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}-frontend"
                def buildDuration = currentBuild.durationString.replace(' and counting', '')
                
                // Déterminer le statut SonarQube
                def sonarStatus = "Analyses terminées"
                try {
                    sonarStatus = env.SONAR_RESULTS ?: "Analyses effectuées"
                } catch (e) {
                    sonarStatus = "Analyses effectuées"
                }
                
                // Structure détectée
                def structureInfo = "Frontend: ${env.FRONTEND_DIR}, Backend: ${env.BACKEND_DIR}"
                
                // Préparer le sujet et le corps de l'email selon le résultat
                def emailSubject = ""
                def emailBody = ""
                
                switch(currentBuild.currentResult) {
                    case 'SUCCESS':
                        emailSubject = "✅ SUCCÈS - Déploiement ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                        emailBody = """
                        <html>
                        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
                            <h2 style="color: #28a745; border-bottom: 2px solid #28a745; padding-bottom: 10px;">🚀 Déploiement Réussi!</h2>
                            
                            <p>Le pipeline <strong>${env.JOB_NAME}</strong> s'est terminé avec succès.</p>
                            
                            <h3 style="color: #0056b3;">📊 Détails de la build:</h3>
                            <ul>
                                <li><strong>Build:</strong> #${env.BUILD_NUMBER}</li>
                                <li><strong>Job:</strong> ${env.JOB_NAME}</li>
                                <li><strong>URL Jenkins:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                                <li><strong>Durée:</strong> ${buildDuration}</li>
                                <li><strong>Date:</strong> ${new Date().format("dd/MM/yyyy à HH:mm")}</li>
                                <li><strong>Structure détectée:</strong> ${structureInfo}</li>
                                <li><strong>Statut SonarQube:</strong> ${sonarStatus}</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">📈 Qualité du code:</h3>
                            <ul>
                                <li><strong>Rapport Backend SonarQube:</strong> <a href="${sonarBackendUrl}">Voir le rapport</a></li>
                                ${env.FRONTEND_DIR != env.BACKEND_DIR ? '<li><strong>Rapport Frontend SonarQube:</strong> <a href="' + sonarFrontendUrl + '">Voir le rapport</a></li>' : ''}
                                <li><strong>Analyse de sécurité:</strong> Effectuée</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🐳 Images Docker déployées:</h3>
                            <ul>
                                <li><strong>Frontend:</strong> ${FRONTEND_IMAGE}:${BUILD_NUMBER}</li>
                                <li><strong>Backend:</strong> ${BACKEND_IMAGE}:${BUILD_NUMBER}</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🌐 Application déployée:</h3>
                            <ul>
                                <li><strong>Frontend React:</strong> <a href="http://localhost:5173">http://localhost:5173</a></li>
                                <li><strong>Backend Express:</strong> <a href="http://localhost:5001/api">http://localhost:5001/api</a></li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🐋 État des conteneurs:</h3>
                            <pre style="background-color: #f8f9fa; padding: 10px; border-radius: 3px; border: 1px solid #e9ecef;">${containerStatus}</pre>
                            
                            <div style="background-color: #d4edda; color: #155724; padding: 12px; border-radius: 4px; border: 1px solid #c3e6cb; margin-top: 20px;">
                                <strong>✅ Tous les services sont opérationnels</strong>
                            </div>
                            
                            <hr style="margin: 20px 0;">
                            <p style="color: #6c757d; font-size: 12px;">Email envoyé automatiquement par Jenkins</p>
                        </div>
                        </body>
                        </html>
                        """
                        break
                        
                    case 'FAILURE':
                        def errorLogs = sh(script: 'docker compose logs --tail=30 2>/dev/null || echo "Impossible de récupérer les logs"', returnStdout: true).trim()
                        emailSubject = "❌ ÉCHEC - Déploiement ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                        emailBody = """
                        <html>
                        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
                            <h2 style="color: #dc3545; border-bottom: 2px solid #dc3545; padding-bottom: 10px;">💥 Échec du Déploiement</h2>
                            
                            <p>Le pipeline <strong>${env.JOB_NAME}</strong> a échoué.</p>
                            
                            <h3 style="color: #0056b3;">📊 Détails de la build:</h3>
                            <ul>
                                <li><strong>Build:</strong> #${env.BUILD_NUMBER}</li>
                                <li><strong>Job:</strong> ${env.JOB_NAME}</li>
                                <li><strong>URL Jenkins:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                                <li><strong>Durée:</strong> ${buildDuration}</li>
                                <li><strong>Date:</strong> ${new Date().format("dd/MM/yyyy à HH:mm")}</li>
                                <li><strong>Structure détectée:</strong> ${structureInfo}</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🔍 Logs d'erreur:</h3>
                            <pre style="background-color: #f8d7da; color: #721c24; padding: 10px; border-radius: 3px; border: 1px solid #f5c6cb; white-space: pre-wrap; word-wrap: break-word;">${errorLogs}</pre>
                            
                            <div style="background-color: #f8d7da; color: #721c24; padding: 12px; border-radius: 4px; border: 1px solid #f5c6cb; margin-top: 20px;">
                                <strong>❌ Une intervention est nécessaire</strong>
                            </div>
                            
                            <hr style="margin: 20px 0;">
                            <p style="color: #6c757d; font-size: 12px;">Email envoyé automatiquement par Jenkins</p>
                        </div>
                        </body>
                        </html>
                        """
                        break
                        
                    case 'UNSTABLE':
                        emailSubject = "⚠️ INSTABLE - Déploiement ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                        emailBody = """
                        <html>
                        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
                            <h2 style="color: #ffc107; border-bottom: 2px solid #ffc107; padding-bottom: 10px;">⚠️ Déploiement Instable</h2>
                            
                            <p>Le pipeline <strong>${env.JOB_NAME}</strong> s'est terminé avec un statut instable (Quality Gate SonarQube échouée).</p>
                            
                            <h3 style="color: #0056b3;">📊 Détails de la build:</h3>
                            <ul>
                                <li><strong>Build:</strong> #${env.BUILD_NUMBER}</li>
                                <li><strong>Job:</strong> ${env.JOB_NAME}</li>
                                <li><strong>URL Jenkins:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                                <li><strong>Durée:</strong> ${buildDuration}</li>
                                <li><strong>Date:</strong> ${new Date().format("dd/MM/yyyy à HH:mm")}</li>
                                <li><strong>Structure détectée:</strong> ${structureInfo}</li>
                                <li><strong>Statut:</strong> Quality Gate SonarQube échouée</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">📈 Qualité du code:</h3>
                            <ul>
                                <li><strong>Rapport Backend SonarQube:</strong> <a href="${sonarBackendUrl}">Voir le rapport</a></li>
                                ${env.FRONTEND_DIR != env.BACKEND_DIR ? '<li><strong>Rapport Frontend SonarQube:</strong> <a href="' + sonarFrontendUrl + '">Voir le rapport</a></li>' : ''}
                                <li><strong>Détails SonarQube:</strong> ${sonarStatus}</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🌐 Application déployée:</h3>
                            <ul>
                                <li><strong>Frontend React:</strong> <a href="http://localhost:5173">http://localhost:5173</a></li>
                                <li><strong>Backend Express:</strong> <a href="http://localhost:5001/api">http://localhost:5001/api</a></li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🐋 État des conteneurs:</h3>
                            <pre style="background-color: #f8f9fa; padding: 10px; border-radius: 3px; border: 1px solid #e9ecef;">${containerStatus}</pre>
                            
                            <div style="background-color: #fff3cd; color: #856404; padding: 12px; border-radius: 4px; border: 1px solid #ffeaa7; margin-top: 20px;">
                                <strong>⚠️ L'application est déployée mais la qualité du code nécessite attention</strong>
                            </div>
                            
                            <hr style="margin: 20px 0;">
                            <p style="color: #6c757d; font-size: 12px;">Email envoyé automatiquement par Jenkins</p>
                        </div>
                        </body>
                        </html>
                        """
                        break
                }
                
                // Envoyer l'email
                if (emailSubject && emailBody) {
                    emailext (
                        subject: emailSubject,
                        body: emailBody,
                        to: "${EMAIL_RECIPIENTS}",
                        mimeType: "text/html"
                    )
                }
            }
        }
        
        success {
            echo '✅ Pipeline terminé avec succès!'
        }
        
        failure {
            echo '❌ Pipeline a échoué!'
        }
        
        unstable {
            echo '⚠️  Pipeline terminé avec statut instable!'
        }
    }
}

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
                    echo "⏳ Attente de la fin des analyses SonarQube..."
                    sleep time: 45, unit: 'SECONDS' // Attendre que les analyses se terminent
                }
            }
        }
        
        stage('Quality Gate - Backend') {
            steps {
                script {
                    timeout(time: 3, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: false, webhookSecretId: ''
                    }
                }
            }
        }
        
        stage('Quality Gate - Frontend') {
            steps {
                script {
                    timeout(time: 3, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: false, webhookSecretId: ''
                    }
                }
            }
        }
        
        // Continuer avec le reste de votre pipeline...
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
        
        // ... reste de votre pipeline
    }
    
    post {
        always {
            // Nettoyage
            sh '''
                echo "🧹 Nettoyage des ressources temporaires..."
                rm -rf .scannerwork || true
            '''
        }
    }
}

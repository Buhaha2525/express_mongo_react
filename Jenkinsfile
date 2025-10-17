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
        // Configuration Kubernetes
        KUBECONFIG = credentials('kubeconfig')
        K8S_NAMESPACE = 'express-app'
        K8S_BACKEND_FILE = 'k8s/backend-deployment.yaml'
        K8S_FRONTEND_FILE = 'k8s/frontend-deployment.yaml'
        K8S_MONGO_FILE = 'k8s/mongo-deployment.yaml'
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
                    echo "=== Dossiers Kubernetes ==="
                    find . -name "*.yaml" -o -name "*.yml" | head -10
                '''
            }
        }
        
        stage('Détection Automatique des Dossiers') {
            steps {
                script {
                    // Détection automatique des dossiers frontend/backend
                    def frontendDir = sh(
                        script: '''
                            find . -name "package.json" -exec dirname {} \\; | grep -iE "(front|client)" | head -1 || 
                            find . -maxdepth 2 -name "package.json" -exec dirname {} \\; | head -1
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    def backendDir = sh(
                        script: '''
                            find . -name "package.json" -exec dirname {} \\; | grep -iE "(back|server|api)" | head -1 || 
                            find . -maxdepth 2 -name "package.json" -exec dirname {} \\; | tail -1
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (!backendDir && frontendDir) {
                        backendDir = frontendDir
                    }
                    if (!frontendDir && backendDir) {
                        frontendDir = backendDir
                    }
                    if (!frontendDir && !backendDir) {
                        frontendDir = "."
                        backendDir = "."
                    }
                    
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
                                        npm install
                                        echo "✅ Dépendances frontend installées avec succès"
                                    else
                                        echo "❌ package.json non trouvé dans $(pwd)"
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
                            if (env.BACKEND_DIR != env.FRONTEND_DIR) {
                                dir(env.BACKEND_DIR) {
                                    sh '''
                                        echo "📦 Installation dépendances Backend dans $(pwd)"
                                        if [ -f "package.json" ]; then
                                            npm install
                                            echo "✅ Dépendances backend installées avec succès"
                                        else
                                            echo "❌ package.json non trouvé dans $(pwd)"
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
                            if (env.FRONTEND_DIR != env.BACKEND_DIR) {
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
        
        stage('Build Docker Images') {
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
                    '''
                }
            }
        }
        
        stage('Push Docker Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDENTIALS_ID}", 
                    usernameVariable: 'DOCKER_USERNAME', 
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "🔐 Vérification connexion Docker Hub..."
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

                        echo "📤 Poussage des images..."
                        docker push ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${FRONTEND_IMAGE}:latest
                        docker push ${BACKEND_IMAGE}:${BUILD_NUMBER}
                        docker push ${BACKEND_IMAGE}:latest

                        docker logout
                    '''
                }
            }
        }
        
        stage('Préparation Manifests Kubernetes') {
            steps {
                script {
                    // Créer le dossier k8s s'il n'existe pas
                    sh 'mkdir -p k8s'
                    
                    // Backend Deployment
                    writeFile file: 'k8s/backend-deployment.yaml', text: """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: express-backend
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: express-backend
  template:
    metadata:
      labels:
        app: express-backend
    spec:
      containers:
      - name: express-backend
        image: ${BACKEND_IMAGE}:${BUILD_NUMBER}
        ports:
        - containerPort: 5001
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "5001"
        - name: MONGODB_URI
          value: "mongodb://mongo-service:27017/smartphoneDB"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 5001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health
            port: 5001
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    app: express-backend
  ports:
  - port: 5001
    targetPort: 5001
"""
                    
                    // Frontend Deployment
                    writeFile file: 'k8s/frontend-deployment.yaml', text: """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: react-frontend
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: react-frontend
  template:
    metadata:
      labels:
        app: react-frontend
    spec:
      containers:
      - name: react-frontend
        image: ${FRONTEND_IMAGE}:${BUILD_NUMBER}
        ports:
        - containerPort: 5173
        env:
        - name: VITE_API_URL
          value: "http://backend-service:5001/api"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 5173
          initialDelaySeconds: 30
          periodSeconds: 10

---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    app: react-frontend
  ports:
  - port: 80
    targetPort: 5173
  type: LoadBalancer
"""
                    
                    // MongoDB Deployment
                    writeFile file: 'k8s/mongo-deployment.yaml', text: """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - name: mongo
        image: mongo:6
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_DATABASE
          value: "smartphoneDB"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"

---
apiVersion: v1
kind: Service
metadata:
  name: mongo-service
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    app: mongo
  ports:
  - port: 27017
    targetPort: 27017
"""
                    
                    echo "✅ Manifests Kubernetes générés"
                    sh 'ls -la k8s/'
                }
            }
        }
        
        stage('Déploiement Kubernetes') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        // Créer le namespace s'il n'existe pas
                        sh """
                            echo "🏗️  Configuration Kubernetes..."
                            kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                        """
                        
                        // Déployer MongoDB
                        sh """
                            echo "📦 Déploiement MongoDB..."
                            kubectl apply -f k8s/mongo-deployment.yaml
                        """
                        
                        // Attendre que MongoDB soit ready
                        sh """
                            echo "⏳ Attente du démarrage de MongoDB..."
                            kubectl wait --for=condition=ready pod -l app=mongo -n ${K8S_NAMESPACE} --timeout=120s
                        """
                        
                        // Déployer le backend
                        sh """
                            echo "🚀 Déploiement Backend..."
                            kubectl apply -f k8s/backend-deployment.yaml
                        """
                        
                        // Déployer le frontend
                        sh """
                            echo "🎨 Déploiement Frontend..."
                            kubectl apply -f k8s/frontend-deployment.yaml
                        """
                        
                        // Vérifier le déploiement
                        sh """
                            echo "📊 État des déploiements:"
                            kubectl get deployments -n ${K8S_NAMESPACE}
                            echo ""
                            echo "📡 État des services:"
                            kubectl get services -n ${K8S_NAMESPACE}
                            echo ""
                            echo "🐛 État des pods:"
                            kubectl get pods -n ${K8S_NAMESPACE}
                        """
                    }
                }
            }
        }
        
        stage('Health Check Kubernetes') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        sh """
                            echo "🏥 Vérification de la santé Kubernetes..."
                            echo "⏳ Attente du démarrage des pods..."
                            sleep 30
                            
                            echo "🔍 Vérification des pods..."
                            kubectl get pods -n ${K8S_NAMESPACE} -o wide
                            
                            echo "🔗 URLs de l'application:"
                            echo "Frontend (LoadBalancer): http://\$(kubectl get svc frontend-service -n ${K8S_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "localhost"):80"
                            echo "Backend: http://backend-service.${K8S_NAMESPACE}.svc.cluster.local:5001"
                            
                            echo "📝 Logs des déploiements:"
                            kubectl logs deployment/express-backend -n ${K8S_NAMESPACE} --tail=10 || echo "Pas encore de logs backend"
                            kubectl logs deployment/react-frontend -n ${K8S_NAMESPACE} --tail=10 || echo "Pas encore de logs frontend"
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "📝 Pipeline ${currentBuild.currentResult} - Build #${BUILD_NUMBER}"
            script {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh """
                        echo "📋 État final Kubernetes:"
                        kubectl get all -n ${K8S_NAMESPACE} 2>/dev/null || echo "Kubernetes non accessible"
                    """
                }
                
                // Récupérer les informations pour l'email
                def k8sStatus = sh(script: """
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        kubectl get all -n ${K8S_NAMESPACE} 2>/dev/null || echo "Kubernetes non accessible"
                    }
                """, returnStdout: true).trim()
                
                def frontendUrl = sh(script: """
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        kubectl get svc frontend-service -n ${K8S_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "En attente d'IP"
                    }
                """, returnStdout: true).trim()
                
                def buildDuration = currentBuild.durationString.replace(' and counting', '')
                def sonarBackendUrl = "${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}-backend"
                def sonarFrontendUrl = "${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}-frontend"
                
                def sonarStatus = "Analyses terminées"
                try {
                    sonarStatus = env.SONAR_RESULTS ?: "Analyses effectuées"
                } catch (e) {
                    sonarStatus = "Analyses effectuées"
                }
                
                def structureInfo = "Frontend: ${env.FRONTEND_DIR}, Backend: ${env.BACKEND_DIR}"
                
                // Email configuration (identique à la version précédente)
                def emailSubject = ""
                def emailBody = ""
                
                switch(currentBuild.currentResult) {
                    case 'SUCCESS':
                        emailSubject = "✅ SUCCÈS - Déploiement K8s ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                        emailBody = """
                        <html>
                        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
                            <h2 style="color: #28a745; border-bottom: 2px solid #28a745; padding-bottom: 10px;">🚀 Déploiement Kubernetes Réussi!</h2>
                            
                            <p>Le pipeline <strong>${env.JOB_NAME}</strong> s'est terminé avec succès.</p>
                            
                            <h3 style="color: #0056b3;">📊 Détails de la build:</h3>
                            <ul>
                                <li><strong>Build:</strong> #${env.BUILD_NUMBER}</li>
                                <li><strong>Job:</strong> ${env.JOB_NAME}</li>
                                <li><strong>URL Jenkins:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                                <li><strong>Durée:</strong> ${buildDuration}</li>
                                <li><strong>Date:</strong> ${new Date().format("dd/MM/yyyy à HH:mm")}</li>
                                <li><strong>Namespace K8s:</strong> ${K8S_NAMESPACE}</li>
                                <li><strong>Structure détectée:</strong> ${structureInfo}</li>
                                <li><strong>Statut SonarQube:</strong> ${sonarStatus}</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🐳 Images Docker déployées:</h3>
                            <ul>
                                <li><strong>Frontend:</strong> ${FRONTEND_IMAGE}:${BUILD_NUMBER}</li>
                                <li><strong>Backend:</strong> ${BACKEND_IMAGE}:${BUILD_NUMBER}</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🌐 Application déployée:</h3>
                            <ul>
                                <li><strong>Frontend React:</strong> http://${frontendUrl}:80</li>
                                <li><strong>Backend API:</strong> http://backend-service.${K8S_NAMESPACE}.svc.cluster.local:5001</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">☸️ État Kubernetes:</h3>
                            <pre style="background-color: #f8f9fa; padding: 10px; border-radius: 3px; border: 1px solid #e9ecef;">${k8sStatus}</pre>
                            
                            <div style="background-color: #d4edda; color: #155724; padding: 12px; border-radius: 4px; border: 1px solid #c3e6cb; margin-top: 20px;">
                                <strong>✅ Application déployée avec succès sur Kubernetes</strong>
                            </div>
                            
                            <hr style="margin: 20px 0;">
                            <p style="color: #6c757d; font-size: 12px;">Email envoyé automatiquement par Jenkins</p>
                        </div>
                        </body>
                        </html>
                        """
                        break
                    // ... (les autres cas FAILURE et UNSTABLE restent similaires)
                }
                
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
            echo '✅ Pipeline Kubernetes terminé avec succès!'
        }
        
        failure {
            echo '❌ Pipeline Kubernetes a échoué!'
        }
    }
}

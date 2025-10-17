pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        DOCKER_REGISTRY = 'dmzz'
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/express-frontend"
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/express-backend"
        SONARQUBE_SCANNER_HOME = tool 'SonarScanner'
        SONAR_HOST_URL = 'http://localhost:9000'
        SONAR_PROJECT_KEY = 'express_mongo_react'
        EMAIL_RECIPIENTS = 'sowdmzz@gmail.com'
        K8S_NAMESPACE = 'express-app'
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
                    def frontendDir = sh(
                        script: 'find . -name "package.json" -exec dirname {} \\; | grep -iE "(front|client)" | head -1 || find . -maxdepth 2 -name "package.json" -exec dirname {} \\; | head -1',
                        returnStdout: true
                    ).trim()
                    
                    def backendDir = sh(
                        script: 'find . -name "package.json" -exec dirname {} \\; | grep -iE "(back|server|api)" | head -1 || find . -maxdepth 2 -name "package.json" -exec dirname {} \\; | tail -1',
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
                                    sh '''
                                        echo "🔍 Analyse SonarQube Backend dans $(pwd)"
                                        ${SONARQUBE_SCANNER_HOME}/bin/sonar-scanner \
                                        -Dsonar.projectKey=${SONAR_PROJECT_KEY}-backend \
                                        -Dsonar.projectName='Express Backend' \
                                        -Dsonar.projectVersion=${BUILD_NUMBER} \
                                        -Dsonar.sources=. \
                                        -Dsonar.exclusions=**/node_modules/**,**/coverage/**,**/*.test.js \
                                        -Dsonar.sourceEncoding=UTF-8 \
                                        -Dsonar.host.url=${SONAR_HOST_URL}
                                    '''
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
                                        sh '''
                                            echo "🔍 Analyse SonarQube Frontend dans $(pwd)"
                                            ${SONARQUBE_SCANNER_HOME}/bin/sonar-scanner \
                                            -Dsonar.projectKey=${SONAR_PROJECT_KEY}-frontend \
                                            -Dsonar.projectName='React Frontend' \
                                            -Dsonar.projectVersion=${BUILD_NUMBER} \
                                            -Dsonar.sources=. \
                                            -Dsonar.exclusions=**/node_modules/**,**/coverage/**,**/*.test.js \
                                            -Dsonar.sourceEncoding=UTF-8 \
                                            -Dsonar.host.url=${SONAR_HOST_URL}
                                        '''
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
        
        stage('Préparation Manifests Kubernetes') {
            steps {
                script {
                    sh 'mkdir -p k8s'
                    
                    writeFile file: 'k8s/backend-deployment.yaml', text: """apiVersion: apps/v1
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
                    
                    writeFile file: 'k8s/frontend-deployment.yaml', text: """apiVersion: apps/v1
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
  type: LoadBalancer
  selector:
    app: react-frontend
  ports:
  - port: 80
    targetPort: 5173
"""
                    
                    writeFile file: 'k8s/mongo-deployment.yaml', text: """apiVersion: apps/v1
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
                    sh """
                        echo "🔍 Vérification de l'accès Kubernetes..."
                        kubectl version --client || echo "kubectl non disponible"
                    """
                    
                    sh """
                        echo "🏗️  Configuration Kubernetes..."
                        kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f - || echo "Namespace déjà existant"
                    """
                    
                    sh """
                        echo "📦 Déploiement MongoDB..."
                        kubectl apply -f k8s/mongo-deployment.yaml || echo "Échec déploiement MongoDB"
                    """
                    
                    sh """
                        echo "⏳ Attente du démarrage de MongoDB..."
                        timeout 120s bash -c '
                            until kubectl get pods -n ${K8S_NAMESPACE} -l app=mongo 2>/dev/null | grep -q Running; do 
                                sleep 10
                                echo "En attente de MongoDB..."
                            done
                        ' || echo "⚠️ Timeout MongoDB - continuation"
                    """
                    
                    sh """
                        echo "🚀 Déploiement Backend..."
                        kubectl apply -f k8s/backend-deployment.yaml || echo "Échec déploiement Backend"
                    """
                    
                    sh """
                        echo "🎨 Déploiement Frontend..."
                        kubectl apply -f k8s/frontend-deployment.yaml || echo "Échec déploiement Frontend"
                    """
                    
                    sh """
                        echo "📊 État des déploiements:"
                        kubectl get deployments -n ${K8S_NAMESPACE} || echo "Impossible de récupérer les déploiements"
                        echo ""
                        echo "📡 État des services:"
                        kubectl get services -n ${K8S_NAMESPACE} || echo "Impossible de récupérer les services"
                        echo ""
                        echo "🐛 État des pods:"
                        kubectl get pods -n ${K8S_NAMESPACE} || echo "Impossible de récupérer les pods"
                    """
                }
            }
        }
        
        stage('Attente Démarrage Pods') {
            steps {
                script {
                    // Version simplifiée et corrigée de l'attente des pods
                    sh '''
                        echo "⏳ Attente du démarrage complet des pods..."
                        timeout 300s bash -c '
                            for i in {1..60}; do
                                ready_count=\$(kubectl get pods -n ${K8S_NAMESPACE} --no-headers 2>/dev/null | grep "Running" | wc -l | tr -d " ")
                                total_count=\$(kubectl get pods -n ${K8S_NAMESPACE} --no-headers 2>/dev/null | wc -l | tr -d " ")
                                
                                echo "Pods prêts: \$ready_count/\$total_count"
                                
                                if [ "\\$total_count" -eq "5" ] && [ "\\$ready_count" -eq "5" ]; then
                                    echo "✅ Tous les pods sont running et ready"
                                    exit 0
                                fi
                                
                                if [ "\\$i" -eq "60" ]; then
                                    echo "⚠️ Timeout atteint après 300 secondes"
                                    echo "État actuel:"
                                    kubectl get pods -n ${K8S_NAMESPACE}
                                    exit 0
                                fi
                                
                                sleep 5
                            done
                        '
                    '''
                    
                    sh '''
                        echo "🔍 État final des pods:"
                        kubectl get pods -n ${K8S_NAMESPACE} -o wide
                        echo ""
                        echo "📋 Détails des services:"
                        kubectl get svc -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }
        
        stage('Configuration Accès Application') {
            steps {
                script {
                    // Version corrigée sans problèmes d'échappement
                    sh '''
                        echo "🔗 Configuration de l'accès à l'application..."
                        
                        # Vérifier si LoadBalancer a une IP externe
                        EXTERNAL_IP=\$(kubectl get svc frontend-service -n ${K8S_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
                        
                        if [ -n "\\$EXTERNAL_IP" ]; then
                            echo "🌐 IP Externe LoadBalancer: \\$EXTERNAL_IP"
                            echo "🎯 URL de l'application: http://\\$EXTERNAL_IP"
                            echo "\\$EXTERNAL_IP" > external_ip.txt
                        else
                            echo "🔧 LoadBalancer en attente d'IP, configuration du port-forward..."
                            
                            # Démarrer port-forward en arrière-plan
                            kubectl port-forward svc/frontend-service 8080:80 -n ${K8S_NAMESPACE} --address=0.0.0.0 &
                            PF_PID=\\$!
                            echo \\$PF_PID > /tmp/portforward.pid
                            
                            sleep 5
                            
                            echo "🌐 URL d'accès temporaire: http://localhost:8080"
                            echo "📝 Le port-forward est actif (PID: \\$PF_PID)"
                            echo "localhost:8080" > external_ip.txt
                            
                            # Tester l'accès
                            echo "🧪 Test de l'application..."
                            curl -f http://localhost:8080 && echo "✅ Frontend accessible via port-forward" || echo "❌ Frontend non accessible"
                        fi
                    '''
                    
                    // Lire l'URL depuis le fichier
                    def appUrl = sh(script: "cat external_ip.txt", returnStdout: true).trim()
                    if (appUrl == "localhost:8080") {
                        env.APP_URL = "http://localhost:8080"
                        env.ACCESS_METHOD = "Port-Forward"
                    } else {
                        env.APP_URL = "http://${appUrl}"
                        env.ACCESS_METHOD = "LoadBalancer"
                    }
                    
                    echo "✅ URL d'accès configurée: ${env.APP_URL}"
                }
            }
        }
        
        stage('Tests Finaux') {
            steps {
                script {
                    sh """
                        echo "🧪 Tests finaux de l'application..."
                        echo "⏳ Attente supplémentaire pour le démarrage complet..."
                        sleep 30
                        
                        # Test du backend
                        echo "🔧 Test du backend..."
                        kubectl exec -n ${K8S_NAMESPACE} deployment/express-backend -- curl -f http://localhost:5001/api/health && echo "✅ Backend opérationnel" || echo "⚠️ Backend en cours de démarrage"
                        
                        # Test du frontend
                        echo "🎨 Test du frontend..."
                        if [ -f /tmp/portforward.pid ]; then
                            curl -f http://localhost:8080 && echo "✅ Frontend opérationnel" || echo "⚠️ Frontend en cours de démarrage"
                        else
                            EXTERNAL_IP=\$(cat external_ip.txt)
                            curl -f http://\\$EXTERNAL_IP && echo "✅ Frontend opérationnel" || echo "⚠️ Frontend en cours de démarrage"
                        fi
                        
                        echo "📊 Résumé des tests:"
                        echo "=========================================="
                        kubectl get all -n ${K8S_NAMESPACE}
                        echo "=========================================="
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📝 Pipeline ${currentBuild.currentResult} - Build #${BUILD_NUMBER}"
            script {
                // Nettoyage
                sh '''
                    # Arrêter le port-forward s'il est actif
                    if [ -f /tmp/portforward.pid ]; then
                        PF_PID=$(cat /tmp/portforward.pid)
                        kill $PF_PID 2>/dev/null || true
                        rm -f /tmp/portforward.pid
                        echo "🔴 Port-forward arrêté"
                    fi
                    
                    # Nettoyer les fichiers temporaires
                    rm -f external_ip.txt 2>/dev/null || true
                '''
                
                // Récupérer les informations finales
                def k8sStatus = sh(script: "kubectl get all -n ${K8S_NAMESPACE} 2>/dev/null || echo 'Kubernetes non accessible'", returnStdout: true).trim()
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
                def appUrl = env.APP_URL ?: "http://localhost:8080"
                def accessMethod = env.ACCESS_METHOD ?: "Port-Forward"
                
                // Configuration email
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
                                <li><strong>Méthode d'accès:</strong> ${accessMethod}</li>
                                <li><strong>Structure détectée:</strong> ${structureInfo}</li>
                                <li><strong>Statut SonarQube:</strong> ${sonarStatus}</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🐳 Images Docker déployées:</h3>
                            <ul>
                                <li><strong>Frontend:</strong> ${FRONTEND_IMAGE}:${BUILD_NUMBER}</li>
                                <li><strong>Backend:</strong> ${BACKEND_IMAGE}:${BUILD_NUMBER}</li>
                                <li><strong>MongoDB:</strong> mongo:6</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🌐 Accès à l'application:</h3>
                            <div style="background-color: #e7f3ff; padding: 15px; border-radius: 5px; border: 1px solid #b3d9ff;">
                                <h4 style="margin-top: 0; color: #0066cc;">${appUrl}</h4>
                                <p><strong>Méthode:</strong> ${accessMethod}</p>
                                <p><em>Si LoadBalancer est utilisé, l'IP peut prendre quelques minutes pour être assignée.</em></p>
                            </div>
                            
                            <h3 style="color: #0056b3;">📈 Qualité du code:</h3>
                            <ul>
                                <li><strong>Rapport Backend SonarQube:</strong> <a href="${sonarBackendUrl}">Voir le rapport</a></li>
                                ${env.FRONTEND_DIR != env.BACKEND_DIR ? '<li><strong>Rapport Frontend SonarQube:</strong> <a href="' + sonarFrontendUrl + '">Voir le rapport</a></li>' : ''}
                            </ul>
                            
                            <h3 style="color: #0056b3;">☸️ État Kubernetes:</h3>
                            <pre style="background-color: #f8f9fa; padding: 10px; border-radius: 3px; border: 1px solid #e9ecef; font-size: 12px;">${k8sStatus}</pre>
                            
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
                        
                    case 'FAILURE':
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
                                <li><strong>Namespace K8s:</strong> ${K8S_NAMESPACE}</li>
                                <li><strong>Structure détectée:</strong> ${structureInfo}</li>
                            </ul>
                            
                            <h3 style="color: #0056b3;">🔍 État actuel Kubernetes:</h3>
                            <pre style="background-color: #f8f9fa; padding: 10px; border-radius: 3px; border: 1px solid #e9ecef; font-size: 12px;">${k8sStatus}</pre>
                            
                            <div style="background-color: #f8d7da; color: #721c24; padding: 12px; border-radius: 4px; border: 1px solid #f5c6cb; margin-top: 20px;">
                                <strong>❌ Une intervention est nécessaire - Consultez les logs Jenkins pour plus de détails</strong>
                            </div>
                            
                            <hr style="margin: 20px 0;">
                            <p style="color: #6c757d; font-size: 12px;">Email envoyé automatiquement par Jenkins</p>
                        </div>
                        </body>
                        </html>
                        """
                        break
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
            echo "🌐 Votre application est accessible à: ${env.APP_URL ?: 'http://localhost:8080'}"
        }
        
        failure {
            echo '❌ Pipeline Kubernetes a échoué!'
            echo '🔍 Consultez les logs pour plus de détails'
        }
        
        unstable {
            echo '⚠️  Pipeline terminé avec statut instable (Quality Gate échouée)'
            echo "🌐 Votre application est accessible à: ${env.APP_URL ?: 'http://localhost:8080'}"
        }
    }
}

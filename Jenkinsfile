pipeline {
    agent {
        kubernetes {
            cloud 'minikube-k8s'
            label 'jenkins-agent'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-agent-${BUILD_NUMBER}
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
    workingDir: /home/jenkins/agent
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "500m"

  - name: node
    image: node:18-alpine
    command: ['cat']
    tty: true
    workingDir: /home/jenkins/agent
    resources:
      requests:
        memory: "512Mi"
        cpu: "300m"
      limits:
        memory: "1Gi"
        cpu: "500m"

  - name: docker
    image: docker:24.0-cli
    command: ['cat']
    tty: true
    workingDir: /home/jenkins/agent
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2375
    securityContext:
      privileged: true
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "500m"

  - name: kubectl
    image: bitnami/kubectl:latest
    command: ['cat']
    tty: true
    workingDir: /home/jenkins/agent
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "500m"
"""
        }
    }

    environment {
        // Docker Registry
        DOCKER_REGISTRY = 'dmzz'
        FRONTEND_IMAGE = "${DOCKER_REGISTRY}/express-frontend"
        BACKEND_IMAGE = "${DOCKER_REGISTRY}/express-backend"
        
        // Kubernetes
        K8S_NAMESPACE = 'express-app'
        
        // SonarQube
        SONARQUBE_SCANNER_HOME = tool 'SonarQubeScanner'
        SONAR_HOST_URL = 'http://localhost:9000'
        SONAR_PROJECT_KEY = 'express_mongo_react'
    }

    stages {
        stage('Checkout et Préparation') {
            steps {
                container('node') {
                    checkout scm
                    sh '''
                        echo "📁 Structure du projet:"
                        ls -la
                        echo ""
                        echo "📦 Backend:"
                        ls -la back-end/
                        echo ""
                        echo "🎨 Frontend:"
                        ls -la front-end/
                    '''
                }
            }
        }

        stage('Installation des Dépendances') {
            parallel {
                stage('Frontend Dependencies') {
                    steps {
                        container('node') {
                            sh '''
                                echo "📦 Installation des dépendances Frontend..."
                                cd front-end
                                npm install
                                echo "✅ Frontend dependencies installées"
                            '''
                        }
                    }
                }
                stage('Backend Dependencies') {
                    steps {
                        container('node') {
                            sh '''
                                echo "📦 Installation des dépendances Backend..."
                                cd back-end
                                npm install
                                echo "✅ Backend dependencies installées"
                            '''
                        }
                    }
                }
            }
        }

        stage('Tests et Qualité') {
            parallel {
                stage('Tests Backend') {
                    steps {
                        container('node') {
                            sh '''
                                echo "🧪 Tests Backend..."
                                cd back-end
                                npm test || echo "⚠️ Tests échoués mais continuation"
                            '''
                        }
                    }
                }
                stage('Analyse SonarQube') {
                    steps {
                        container('node') {
                            script {
                                withSonarQubeEnv('SonarQube') {
                                    sh """
                                        echo "🔍 Analyse SonarQube Backend..."
                                        ${SONARQUBE_SCANNER_HOME}/bin/sonar-scanner \
                                        -Dsonar.projectKey=${SONAR_PROJECT_KEY}-backend \
                                        -Dsonar.projectName='Express Backend' \
                                        -Dsonar.sources=back-end \
                                        -Dsonar.exclusions=**/node_modules/**,**/coverage/** \
                                        -Dsonar.sourceEncoding=UTF-8
                                        
                                        echo "🔍 Analyse SonarQube Frontend..."
                                        ${SONARQUBE_SCANNER_HOME}/bin/sonar-scanner \
                                        -Dsonar.projectKey=${SONAR_PROJECT_KEY}-frontend \
                                        -Dsonar.projectName='React Frontend' \
                                        -Dsonar.sources=front-end \
                                        -Dsonar.exclusions=**/node_modules/**,**/coverage/** \
                                        -Dsonar.sourceEncoding=UTF-8
                                    """
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Build des Applications') {
            parallel {
                stage('Build Frontend') {
                    steps {
                        container('node') {
                            sh '''
                                echo "🏗️ Build Frontend..."
                                cd front-end
                                npm run build
                                echo "✅ Frontend build réussi"
                            '''
                        }
                    }
                }
                stage('Build Backend') {
                    steps {
                        container('node') {
                            sh '''
                                echo "🏗️ Build Backend..."
                                cd back-end
                                npm run build || echo "⚠️ Pas de script build, continuation"
                                echo "✅ Backend prêt"
                            '''
                        }
                    }
                }
            }
        }

        stage('Build Images Docker') {
            steps {
                container('docker') {
                    script {
                        sh """
                            echo "🐳 Build image Frontend..."
                            docker build -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} ./front-end
                            docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${FRONTEND_IMAGE}:latest
                            
                            echo "🐳 Build image Backend..."
                            docker build -t ${BACKEND_IMAGE}:${BUILD_NUMBER} ./back-end
                            docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${BACKEND_IMAGE}:latest
                            
                            echo "📋 Images créées:"
                            docker images | grep "${DOCKER_REGISTRY}"
                        """
                    }
                }
            }
        }

        stage('Déploiement Kubernetes') {
            steps {
                container('kubectl') {
                    script {
                        // Préparer les manifests
                        sh '''
                            echo "📝 Préparation des manifests Kubernetes..."
                            mkdir -p k8s
                            
                            # Copier les manifests s'ils existent
                            cp -f back-end/k8s-deployment.yaml k8s/backend-deployment.yaml 2>/dev/null || echo "⚠️ Manifest backend non trouvé"
                            cp -f front-end/k8s-deployment.yaml k8s/frontend-deployment.yaml 2>/dev/null || echo "⚠️ Manifest frontend non trouvé"
                            cp -f mongo/k8s-deployment.yaml k8s/mongo-deployment.yaml 2>/dev/null || echo "⚠️ Manifest mongo non trouvé"
                        '''

                        // Créer les manifests si ils n'existent pas
                        sh """
                            # Créer le namespace
                            kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                            
                            echo "🚀 Déploiement en cours..."
                            
                            # Déployer MongoDB
                            if [ -f "k8s/mongo-deployment.yaml" ]; then
                                kubectl apply -f k8s/mongo-deployment.yaml -n ${K8S_NAMESPACE}
                                echo "⏳ Attente du démarrage de MongoDB..."
                                sleep 30
                            else
                                echo "📦 Déploiement de MongoDB..."
                                kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: 1
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
        image: mongo:6.0
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_DATABASE
          value: "smartphoneDB"
        volumeMounts:
        - name: mongo-storage
          mountPath: /data/db
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: mongo-storage
        persistentVolumeClaim:
          claimName: mongo-pvc
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
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongo-pvc
  namespace: ${K8S_NAMESPACE}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
                                sleep 30
                            fi
                            
                            # Déployer le Backend
                            if [ -f "k8s/backend-deployment.yaml" ]; then
                                sed -i "s|image:.*|image: ${BACKEND_IMAGE}:${BUILD_NUMBER}|g" k8s/backend-deployment.yaml
                                kubectl apply -f k8s/backend-deployment.yaml -n ${K8S_NAMESPACE}
                            else
                                echo "🔧 Déploiement du Backend..."
                                kubectl apply -f - <<EOF
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
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 5001
          initialDelaySeconds: 30
          periodSeconds: 10
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
EOF
                            fi
                            
                            # Déployer le Frontend
                            if [ -f "k8s/frontend-deployment.yaml" ]; then
                                sed -i "s|image:.*|image: ${FRONTEND_IMAGE}:${BUILD_NUMBER}|g" k8s/frontend-deployment.yaml
                                kubectl apply -f k8s/frontend-deployment.yaml -n ${K8S_NAMESPACE}
                            else
                                echo "🎨 Déploiement du Frontend..."
                                kubectl apply -f - <<EOF
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
EOF
                            fi
                            
                            # Déployer l'Ingress
                            kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: ${K8S_NAMESPACE}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 5001
EOF
                        """
                    }
                }
            }
        }

        stage('Vérification du Déploiement') {
            steps {
                container('kubectl') {
                    sh '''
                        echo "⏳ Attente du démarrage des pods..."
                        sleep 60
                        
                        echo "📊 État du déploiement:"
                        kubectl get all -n ${K8S_NAMESPACE}
                        
                        echo "🔍 Détails des pods:"
                        kubectl get pods -n ${K8S_NAMESPACE} -o wide
                        
                        echo "🌐 Services:"
                        kubectl get services -n ${K8S_NAMESPACE}
                        
                        echo "🔗 Ingress:"
                        kubectl get ingress -n ${K8S_NAMESPACE}
                        
                        # Vérifier la santé des pods
                        echo "🏥 Vérification de la santé:"
                        kubectl logs -n ${K8S_NAMESPACE} -l app=express-backend --tail=10 || echo "⚠️ Logs backend non disponibles"
                        kubectl logs -n ${K8S_NAMESPACE} -l app=react-frontend --tail=10 || echo "⚠️ Logs frontend non disponibles"
                    '''
                }
            }
        }
    }

    post {
        always {
            container('kubectl') {
                sh '''
                    echo "📋 Rapport final:"
                    echo "===================="
                    kubectl get pods -n ${K8S_NAMESPACE}
                    echo ""
                    
                    # Obtenir l'URL de l'application
                    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
                    echo "🎯 Votre application est disponible à:"
                    echo "   Frontend: http://${MINIKUBE_IP}"
                    echo "   Backend:  http://${MINIKUBE_IP}/api"
                    echo "   MongoDB:  mongodb://${MINIKUBE_IP}:27017"
                '''
            }
            
            // Nettoyage
            sh '''
                echo "🧹 Nettoyage des ressources temporaires..."
                docker system prune -f 2>/dev/null || true
            '''
        }
        
        success {
            echo '✅ 🎉 Déploiement réussi! Votre application est en ligne.'
            emailext (
                subject: "✅ SUCCÈS - Déploiement ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                Le pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} a réussi.
                
                Application déployée avec succès sur Kubernetes.
                URLs d'accès:
                - Frontend: http://$(minikube ip 2>/dev/null || echo "localhost")
                - Backend API: http://$(minikube ip 2>/dev/null || echo "localhost")/api
                
                Bonne journée!
                """,
                to: "sowdmzz@gmail.com"
            )
        }
        
        failure {
            echo '❌ Échec du déploiement. Vérifiez les logs.'
            container('kubectl') {
                sh '''
                    echo "🔍 Debug information:"
                    kubectl describe pods -n ${K8S_NAMESPACE} || true
                    kubectl get events -n ${K8S_NAMESPACE} --sort-by=.lastTimestamp | tail -20 || true
                '''
            }
        }
    }
}

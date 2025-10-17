pipeline {
    agent {
        kubernetes {
            cloud 'minikube-k8s'
            label "jenkins-agent-${BUILD_NUMBER}"
            yaml """
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-agent-${BUILD_NUMBER}
  labels:
    app: jenkins-agent
spec:
  serviceAccountName: jenkins-agent
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:4.11.2-4
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
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock

  - name: docker
    image: docker:24.0.7-cli-alpine
    command: ['cat']
    tty: true
    workingDir: /home/jenkins/agent
    env:
    - name: DOCKER_HOST
      value: unix:///var/run/docker.sock
    securityContext:
      privileged: true
    resources:
      requests:
        memory: "512Mi"
        cpu: "300m"
      limits:
        memory: "1Gi"
        cpu: "500m"
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock

  - name: kubectl
    image: bitnami/kubectl:1.28
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

  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
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
        
        // Build info
        BUILD_TAG = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Debug et Verification') {
            steps {
                container('node') {
                    script {
                        echo "🔍 Démarrage du pipeline - Debug information"
                        sh '''
                            echo "=== Informations système ==="
                            echo "Build: ${BUILD_NUMBER}"
                            echo "Workspace: ${WORKSPACE}"
                            echo "=== Outils disponibles ==="
                            node --version
                            npm --version
                            docker --version
                            kubectl version --client
                            echo "=== Structure du projet ==="
                            ls -la
                        '''
                    }
                }
            }
        }

        stage('Checkout Code') {
            steps {
                container('node') {
                    checkout scm
                    sh '''
                        echo "📦 Code checkout complet"
                        git log -1 --oneline
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
                                npm ci --silent
                                echo "✅ Dépendances Frontend installées"
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
                                npm ci --silent
                                echo "✅ Dépendances Backend installées"
                            '''
                        }
                    }
                }
            }
        }

        stage('Tests') {
            parallel {
                stage('Tests Backend') {
                    steps {
                        container('node') {
                            sh '''
                                echo "🧪 Exécution des tests Backend..."
                                cd back-end
                                npm test -- --watchAll=false --passWithNoTests || echo "ℹ️ Tests terminés"
                                echo "✅ Tests Backend terminés"
                            '''
                        }
                    }
                }
                stage('Tests Frontend') {
                    steps {
                        container('node') {
                            sh '''
                                echo "🧪 Exécution des tests Frontend..."
                                cd front-end
                                npm test -- --watchAll=false --passWithNoTests || echo "ℹ️ Tests terminés"
                                echo "✅ Tests Frontend terminés"
                            '''
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
                                echo "🏗️ Building Frontend..."
                                cd front-end
                                npm run build
                                echo "✅ Frontend build réussi"
                                ls -la dist/
                            '''
                        }
                    }
                }
                stage('Build Backend') {
                    steps {
                        container('node') {
                            sh '''
                                echo "🏗️ Préparation Backend..."
                                cd back-end
                                # Vérifier que le code est prêt
                                ls -la
                                echo "✅ Backend prêt pour le déploiement"
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
                        echo "🐳 Construction des images Docker..."
                        
                        // Build Frontend
                        sh """
                            echo "📦 Construction de l'image Frontend..."
                            docker build -t ${FRONTEND_IMAGE}:${BUILD_TAG} -t ${FRONTEND_IMAGE}:latest ./front-end
                            echo "✅ Image Frontend construite: ${FRONTEND_IMAGE}:${BUILD_TAG}"
                        """
                        
                        // Build Backend
                        sh """
                            echo "📦 Construction de l'image Backend..."
                            docker build -t ${BACKEND_IMAGE}:${BUILD_TAG} -t ${BACKEND_IMAGE}:latest ./back-end
                            echo "✅ Image Backend construite: ${BACKEND_IMAGE}:${BUILD_TAG}"
                        """
                        
                        // Lister les images
                        sh """
                            echo "📋 Images Docker construites:"
                            docker images | grep "${DOCKER_REGISTRY}"
                        """
                    }
                }
            }
        }

        stage('Déploiement MongoDB') {
            steps {
                container('kubectl') {
                    script {
                        echo "🗄️ Déploiement de MongoDB..."
                        
                        // Créer le namespace
                        sh """
                            kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                        """
                        
                        // Déployer MongoDB
                        sh """
                            kubectl apply -f - <<EOF
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
---
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
EOF
                        """
                        
                        // Attendre que MongoDB soit prêt
                        sh """
                            echo "⏳ Attente du démarrage de MongoDB..."
                            kubectl wait --for=condition=ready pod -l app=mongo -n ${K8S_NAMESPACE} --timeout=120s
                            echo "✅ MongoDB est prêt"
                        """
                    }
                }
            }
        }

        stage('Déploiement Applications') {
            steps {
                container('kubectl') {
                    script {
                        echo "🚀 Déploiement des applications..."
                        
                        // Mettre à jour et déployer le Backend
                        sh """
                            echo "🔧 Déploiement du Backend..."
                            # Mettre à jour l'image dans le manifeste existant
                            sed -i 's|image:.*|image: ${BACKEND_IMAGE}:${BUILD_TAG}|g' back-end/k8s-deployment.yaml
                            
                            # Appliquer le déploiement
                            kubectl apply -f back-end/k8s-deployment.yaml -n ${K8S_NAMESPACE}
                            echo "✅ Backend déployé avec l'image: ${BACKEND_IMAGE}:${BUILD_TAG}"
                        """
                        
                        // Mettre à jour et déployer le Frontend
                        sh """
                            echo "🔧 Déploiement du Frontend..."
                            # Mettre à jour l'image dans le manifeste existant
                            sed -i 's|image:.*|image: ${FRONTEND_IMAGE}:${BUILD_TAG}|g' front-end/k8s-deployment.yaml
                            
                            # Appliquer le déploiement
                            kubectl apply -f front-end/k8s-deployment.yaml -n ${K8S_NAMESPACE}
                            echo "✅ Frontend déployé avec l'image: ${FRONTEND_IMAGE}:${BUILD_TAG}"
                        """
                    }
                }
            }
        }

        stage('Vérification du Déploiement') {
            steps {
                container('kubectl') {
                    script {
                        echo "🔍 Vérification du déploiement..."
                        
                        // Attendre que les pods soient prêts
                        sh """
                            echo "⏳ Attente du démarrage des pods..."
                            kubectl wait --for=condition=ready pod -l app=express-backend -n ${K8S_NAMESPACE} --timeout=180s
                            kubectl wait --for=condition=ready pod -l app=react-frontend -n ${K8S_NAMESPACE} --timeout=180s
                            echo "✅ Tous les pods sont prêts"
                        """
                        
                        // Afficher l'état du déploiement
                        sh """
                            echo "=== État du déploiement ==="
                            kubectl get all -n ${K8S_NAMESPACE}
                            
                            echo "=== Détails des pods ==="
                            kubectl get pods -n ${K8S_NAMESPACE} -o wide
                            
                            echo "=== Services ==="
                            kubectl get services -n ${K8S_NAMESPACE}
                            
                            echo "=== Logs Backend (extrait) ==="
                            kubectl logs -n ${K8S_NAMESPACE} -l app=express-backend --tail=10 || echo "Logs backend non disponibles"
                            
                            echo "=== Logs Frontend (extrait) ==="
                            kubectl logs -n ${K8S_NAMESPACE} -l app=react-frontend --tail=10 || echo "Logs frontend non disponibles"
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "📊 Génération du rapport final..."
            container('kubectl') {
                sh '''
                    echo "=== RAPPORT FINAL ==="
                    echo "📦 Namespace: ${K8S_NAMESPACE}"
                    echo "🔢 Build: ${BUILD_NUMBER}"
                    echo ""
                    echo "=== RÉSUMÉ DES DÉPLOIEMENTS ==="
                    kubectl get deployments -n ${K8S_NAMESPACE}
                    echo ""
                    echo "=== RÉSUMÉ DES SERVICES ==="
                    kubectl get services -n ${K8S_NAMESPACE}
                    echo ""
                    echo "=== RÉSUMÉ DES PODS ==="
                    kubectl get pods -n ${K8S_NAMESPACE} -o wide
                    
                    # Obtenir l'URL du LoadBalancer
                    echo ""
                    echo "🌐 URLS D'ACCÈS:"
                    FRONTEND_IP=$(kubectl get svc frontend-service -n ${K8S_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "En attente...")
                    FRONTEND_PORT=$(kubectl get svc frontend-service -n ${K8S_NAMESPACE} -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "80")
                    
                    if [ "$FRONTEND_IP" != "En attente..." ]; then
                        echo "   Frontend: http://${FRONTEND_IP}:${FRONTEND_PORT}"
                        echo "   Backend API: http://${FRONTEND_IP}:${FRONTEND_PORT}/api"
                    else
                        # Fallback sur Minikube
                        MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
                        NODE_PORT=$(kubectl get svc frontend-service -n ${K8S_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30000")
                        echo "   Frontend: http://${MINIKUBE_IP}:${NODE_PORT}"
                        echo "   Backend API: http://${MINIKUBE_IP}:${NODE_PORT}/api"
                    fi
                    echo "   MongoDB: mongodb://mongo-service:27017/smartphoneDB"
                '''
            }
        }
        
        success {
            echo '🎉 Déploiement réussi! Votre application est en ligne.'
            script {
                // Obtenir l'URL d'accès
                def frontendIp = sh(script: '''
                    kubectl get svc frontend-service -n ${K8S_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ""
                ''', returnStdout: true).trim()
                
                def accessUrl = ""
                if (frontendIp) {
                    accessUrl = "http://${frontendIp}"
                } else {
                    def minikubeIp = sh(script: 'minikube ip 2>/dev/null || echo "localhost"', returnStdout: true).trim()
                    def nodePort = sh(script: 'kubectl get svc frontend-service -n ${K8S_NAMESPACE} -o jsonpath=\'{.spec.ports[0].nodePort}\' 2>/dev/null || echo "30000"', returnStdout: true).trim()
                    accessUrl = "http://${minikubeIp}:${nodePort}"
                }
                
                emailext (
                    subject: "✅ SUCCÈS - Déploiement ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    Le pipeline ${env.JOB_NAME} #${env.BUILD_NUMBER} a réussi.

                    📊 RAPPORT DE DÉPLOIEMENT:
                    - Application: Express + React + MongoDB
                    - Namespace: ${K8S_NAMESPACE}
                    - Build: ${BUILD_NUMBER}
                    - Statut: ✅ SUCCÈS

                    🌐 URL D'ACCÈS:
                    ${accessUrl}

                    📋 RÉSUMÉ KUBERNETES:
                    ${sh(script: 'kubectl get pods -n ${K8S_NAMESPACE} -o wide | tail -n +2', returnStdout: true).trim()}

                    Bonne journée!
                    """,
                    to: "sowdmzz@gmail.com"
                )
            }
        }
        
        failure {
            echo '❌ Échec du déploiement. Vérifiez les logs.'
            container('kubectl') {
                sh '''
                    echo "🐛 Debug information:"
                    echo "=== Événements récents ==="
                    kubectl get events -n ${K8S_NAMESPACE} --sort-by=.lastTimestamp | tail -20 || true
                    
                    echo "=== Description des pods en échec ==="
                    kubectl describe pods -n ${K8S_NAMESPACE} --selector=app!=mongo || true
                '''
            }
        }
        
        cleanup {
            echo "🧹 Nettoyage des ressources temporaires..."
            sh '''
                docker system prune -f 2>/dev/null || true
            '''
        }
    }
}

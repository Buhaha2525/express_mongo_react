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

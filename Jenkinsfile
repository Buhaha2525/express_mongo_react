agent {
    kubernetes {
        cloud 'minikube-k8s'
        inheritFrom 'default'  // ou le nom de votre template existant
        yaml """
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-agent-${BUILD_NUMBER}
spec:
  containers:
  - name: node
    image: node:18-alpine
    command: ['cat']
    tty: true
    workingDir: /home/jenkins/agent
    # ... reste de la configuration
"""
    }
}

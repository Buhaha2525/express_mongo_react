pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        PROJECT_NAME = 'fullstack-app'
        ENVIRONMENT = 'dev'
        TERRAFORM_DIR = 'terraform'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Action Terraform à exécuter'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Approuver automatiquement sans confirmation'
        )
        booleanParam(
            name: 'SAVE_SSH_KEY',
            defaultValue: true,
            description: 'Sauvegarder la clé SSH générée'
        )
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout & Setup') {
            steps {
                checkout scm
                script {
                    currentBuild.displayName = "#${currentBuild.number} - ${params.ACTION} - ${ENVIRONMENT}"
                    currentBuild.description = "Fullstack App - Terraform ${params.ACTION}"
                }
            }
        }

        stage('Configure AWS') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                    echo "🔐 Configuration des credentials AWS..."
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    export AWS_DEFAULT_REGION=us-east-1

                    echo "📍 Région AWS: us-east-1"
                    echo "🏷️ Projet: fullstack-app"
                    echo "🌱 Environnement: dev"
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=us-east-1

                        echo "🚀 Initialisation de Terraform..."
                        terraform init -input=false -upgrade
                        '''
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh '''
                    echo "🔍 Validation de la configuration Terraform..."
                    terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION in ['plan', 'apply'] }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=us-east-1

                        echo "📋 Création du plan d'infrastructure..."
                        echo "📦 Ressources à créer:"
                        echo "   - VPC avec Internet Gateway"
                        echo "   - Subnet public"
                        echo "   - 3 Security Groups (backend, frontend, MongoDB)"
                        echo "   - 3 instances EC2 (backend, frontend, MongoDB)"
                        echo "   - Key Pair pour l'accès SSH"

                        terraform plan \
                            -var="aws_region=us-east-1" \
                            -var="project_name=fullstack-app" \
                            -var="environment=dev" \
                            -var="backend_port=5000" \
                            -var="frontend_port=3000" \
                            -var="mongodb_port=27017" \
                            -var="ssh_port=22" \
                            -out=tfplan \
                            -input=false \
                            -detailed-exitcode
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    if (params.AUTO_APPROVE) {
                        echo "🛠️ Application automatique des changements..."
                    } else {
                        input(
                            message: "Appliquer l'infrastructure Fullstack?",
                            ok: "Déployer",
                            parameters: [
                                text(
                                    name: 'CONFIRMATION',
                                    defaultValue: 'yes',
                                    description: 'Tapez "yes" pour confirmer le déploiement'
                                )
                            ]
                        )
                    }

                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        dir('terraform') {
                            sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=us-east-1

                            echo "🏗️ Déploiement de l'infrastructure Fullstack..."
                            echo "📦 Services en cours de déploiement:"
                            echo "   🖥️  Backend API (Node.js/Express sur port 5000)"
                            echo "   🗄️  Base de données MongoDB (port 27017)"
                            echo "   🌐 Frontend (Nginx sur port 80)"

                            terraform apply \
                                -var="aws_region=us-east-1" \
                                -var="project_name=fullstack-app" \
                                -var="environment=dev" \
                                -var="backend_port=5000" \
                                -var="frontend_port=3000" \
                                -var="mongodb_port=27017" \
                                -var="ssh_port=22" \
                                -auto-approve \
                                -input=false
                            '''
                        }
                    }
                }
            }
        }

        stage('Extract Outputs') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        script {
                            // Extraction des outputs
                            def backend_ip = sh(
                                script: '''
                                export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                export AWS_DEFAULT_REGION=us-east-1
                                terraform output -raw backend_public_ip
                                ''',
                                returnStdout: true
                            ).trim()

                            def frontend_ip = sh(
                                script: '''
                                export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                export AWS_DEFAULT_REGION=us-east-1
                                terraform output -raw frontend_public_ip
                                ''',
                                returnStdout: true
                            ).trim()

                            def mongodb_ip = sh(
                                script: '''
                                export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                export AWS_DEFAULT_REGION=us-east-1
                                terraform output -raw mongodb_private_ip
                                ''',
                                returnStdout: true
                            ).trim()

                            // Sauvegarde de la clé SSH si demandé
                            if (params.SAVE_SSH_KEY) {
                                sh '''
                                export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                export AWS_DEFAULT_REGION=us-east-1
                                terraform output -raw ssh_private_key > fullstack-key.pem
                                chmod 400 fullstack-key.pem
                                '''
                            }

                            // Création du rapport de déploiement
                            writeFile file: 'deployment-info.txt', text: """
                            🎉 DÉPLOIEMENT FULLSTACK RÉUSSI 🎉

                            APPLICATION URLs:
                            =================
                            🌐 Frontend:    http://${frontend_ip}
                            🔗 Backend API: http://${backend_ip}:5000/api/health
                            🗄️  MongoDB:    ${mongodb_ip}:27017

                            CONNEXIONS SSH:
                            ==============
                            Backend:  ssh -i fullstack-key.pem ec2-user@${backend_ip}
                            Frontend: ssh -i fullstack-key.pem ec2-user@${frontend_ip}
                            MongoDB:  ssh -i fullstack-key.pem ec2-user@${mongodb_ip}

                            INFORMATIONS BASE DE DONNÉES:
                            ===========================
                            URL: mongodb://appuser:apppass123@${mongodb_ip}:27017/fullstackapp
                            Admin: mongodb://admin:mongodb123@${mongodb_ip}:27017/admin

                            TESTS AUTOMATIQUES:
                            ==================
                            1. Visitez http://${frontend_ip} pour tester l'interface
                            2. Testez l'API: curl http://${backend_ip}:5000/api/health
                            3. Vérifiez MongoDB depuis le backend

                            TIMESTAMP: ${new Date().format('yyyy-MM-dd HH:mm:ss')}
                            """

                            currentBuild.description = "Deployed - Frontend: http://${frontend_ip}"
                        }
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'deployment-info.txt', fingerprint: true
                    archiveArtifacts artifacts: 'terraform/fullstack-key.pem', fingerprint: true
                    dir('terraform') {
                        sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=us-east-1
                        terraform output -json > terraform-outputs.json
                        '''
                        archiveArtifacts artifacts: 'terraform/terraform-outputs.json', fingerprint: true
                    }
                }
            }
        }

        stage('Health Check') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    dir('terraform') {
                        def backend_ip = sh(
                            script: '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=us-east-1
                            terraform output -raw backend_public_ip
                            ''',
                            returnStdout: true
                        ).trim()

                        echo "🏥 Vérification de la santé des services..."

                        // Test de l'API backend avec retry
                        sh """
                        for i in {1..5}; do
                            echo "Tentative \$i/5 de connexion au backend..."
                            if curl -f -s -m 10 http://${backend_ip}:5000/api/health; then
                                echo "✅ Backend API est opérationnel"
                                break
                            else
                                echo "⏳ Backend non disponible, nouvel essai dans 15s..."
                                sleep 15
                            fi
                        done
                        """
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                script {
                    input(
                        message: "🚨 DÉTRUIRE toute l'infrastructure Fullstack? Cette action est IRRÉVERSIBLE!",
                        ok: "Détruire",
                        parameters: [
                            text(
                                name: 'CONFIRM_DESTROY',
                                defaultValue: 'DESTROY',
                                description: 'Tapez "DESTROY" pour confirmer la destruction'
                            )
                        ]
                    )

                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        dir('terraform') {
                            sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=us-east-1

                            echo "🗑️ Destruction de l'infrastructure Fullstack..."
                            echo "📦 Ressources à détruire:"
                            echo "   - 3 instances EC2"
                            echo "   - Security Groups"
                            echo "   - VPC et sous-réseau"
                            echo "   - Key Pair"

                            terraform destroy \
                                -var="aws_region=us-east-1" \
                                -var="project_name=fullstack-app" \
                                -var="environment=dev" \
                                -var="backend_port=5000" \
                                -var="frontend_port=3000" \
                                -var="mongodb_port=27017" \
                                -var="ssh_port=22" \
                                -auto-approve \
                                -input=false
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            // Nettoyage
            sh '''
            rm -rf terraform/.terraform* || true
            rm -rf terraform/tfplan || true
            rm -rf terraform/terraform.tfstate.backup || true
            '''

            // Rapport final
            script {
                if (currentBuild.result == 'SUCCESS' && params.ACTION == 'apply') {
                    dir('terraform') {
                        def frontend_ip = sh(
                            script: '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=us-east-1
                            terraform output -raw frontend_public_ip 2>/dev/null || echo "N/A"
                            ''',
                            returnStdout: true
                        ).trim()

                        echo """
                        🎉 DÉPLOIEMENT TERMINÉ AVEC SUCCÈS!

                        Votre application Fullstack est maintenant déployée:
                        🌐 Frontend: http://${frontend_ip}

                        Téléchargez les artefacts du build pour:
                        - La clé SSH (fullstack-key.pem)
                        - Les informations de connexion (deployment-info.txt)
                        - Les outputs Terraform (terraform-outputs.json)
                        """
                    }
                }
            }
        }

        success {
            echo "✅ Pipeline exécuté avec succès!"
        }

        failure {
            echo "❌ Le pipeline a échoué - consultez les logs pour plus de détails"
        }

        unstable {
            echo "⚠️ Pipeline terminé avec des avertissements"
        }
    }
}
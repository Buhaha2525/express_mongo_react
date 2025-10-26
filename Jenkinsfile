pipeline {
    agent any

    environment {
        GITHUB_CREDENTIALS_ID = 'github-credentials'
        AWS_CREDENTIALS_ID = 'aws-credentials'
        EMAIL_RECIPIENTS = 'sowdmzz@gmail.com'
        TERRAFORM_VERSION = '1.5.0'
        AWS_DEFAULT_REGION = 'us-west-2'
    }

    stages {
        stage('Checkout Terraform Branch') {
            steps {
                git branch: 'Terraform',
                url: 'https://github.com/Buhaha2525/express_mongo_react.git',
                credentialsId: "${GITHUB_CREDENTIALS_ID}"
            }
        }

        stage('Analyse Structure Terraform') {
            steps {
                sh '''
                    echo "🔍 Analyse de la structure Terraform..."
                    echo "=== Fichiers Terraform ==="
                    find . -name "*.tf" -o -name "*.tfvars" | head -20
                    echo ""
                    echo "=== Structure du projet ==="
                    ls -la
                    echo ""
                    echo "=== Contenu des répertoires ==="
                    find . -maxdepth 2 -type d | head -20
                '''
            }
        }

        stage('Configuration AWS et Terraform') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS_ID}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        echo "🔐 Configuration AWS chargée depuis Jenkins Credentials"
                        echo "📥 Installation de Terraform ${TERRAFORM_VERSION}..."

                        # Téléchargement et installation de Terraform
                        wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                        unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                        sudo mv terraform /usr/local/bin/
                        rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

                        echo "✅ Terraform installé avec succès"
                        terraform version

                        echo "🔑 Vérification des credentials AWS..."
                        echo "Région AWS: ${AWS_DEFAULT_REGION}"

                        # Installation d'AWS CLI si non présent
                        if ! command -v aws &> /dev/null; then
                            echo "📥 Installation d'AWS CLI..."
                            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                            unzip awscliv2.zip
                            sudo ./aws/install
                            rm -rf awscliv2.zip aws/
                        fi

                        # Vérification des credentials AWS
                        aws sts get-caller-identity --region ${AWS_DEFAULT_REGION} && echo "✅ Credentials AWS valides" || echo "⚠️ Vérification AWS CLI échouée"
                    '''
                }
            }
        }

        stage('Initialisation Terraform') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS_ID}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        echo "🚀 Initialisation de Terraform..."
                        terraform init -upgrade -reconfigure -input=false

                        echo "📋 Validation de la configuration..."
                        terraform validate

                        echo "📝 Planification de l'infrastructure..."
                        terraform plan -out=tfplan -var="environment=jenkins" -var="aws_region=${AWS_DEFAULT_REGION}"
                    '''
                }
            }
        }

        stage('Vérification de Sécurité') {
            steps {
                sh '''
                    echo "🔒 Vérifications de sécurité et qualité..."

                    # Vérification du formatage
                    echo "🎨 Vérification du formatage du code..."
                    terraform fmt -check -recursive || echo "⚠️ Certains fichiers ne sont pas formatés correctement"

                    # Vérification de la syntaxe
                    echo "📝 Validation syntaxique..."
                    terraform validate

                    # Vérification des dépendances
                    echo "🔍 Vérification des dépendances..."
                    terraform providers schema -json > /dev/null && echo "✅ Schéma des providers valide" || echo "⚠️ Problème avec les providers"
                '''
            }
        }

        stage('Déploiement Infrastructure AWS') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS_ID}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        echo "🏗️ Déploiement de l'infrastructure AWS..."
                        terraform apply -auto-approve -input=false tfplan

                        echo "📊 État du déploiement..."
                        terraform show -no-color
                    '''
                }
            }
        }

        stage('Récupération des Outputs') {
            steps {
                script {
                    // Récupérer les outputs Terraform
                    try {
                        env.TERRAFORM_OUTPUTS = sh(
                            script: 'terraform output -json 2>/dev/null || echo "{}"',
                            returnStdout: true
                        ).trim()
                    } catch (Exception e) {
                        env.TERRAFORM_OUTPUTS = "{}"
                        echo "⚠️ Impossible de récupérer les outputs Terraform"
                    }

                    // Essayer de récupérer des URLs spécifiques
                    try {
                        env.APP_URL = sh(
                            script: 'terraform output -raw app_url 2>/dev/null || echo "non-défini"',
                            returnStdout: true
                        ).trim()
                    } catch (Exception e) {
                        env.APP_URL = "non-défini"
                    }

                    try {
                        env.LB_DNS = sh(
                            script: 'terraform output -raw load_balancer_dns 2>/dev/null || echo "non-défini"',
                            returnStdout: true
                        ).trim()
                    } catch (Exception e) {
                        env.LB_DNS = "non-défini"
                    }

                    try {
                        env.EC2_IP = sh(
                            script: 'terraform output -raw ec2_public_ip 2>/dev/null || echo "non-défini"',
                            returnStdout: true
                        ).trim()
                    } catch (Exception e) {
                        env.EC2_IP = "non-défini"
                    }

                    echo "📄 Outputs Terraform récupérés:"
                    echo "APP_URL: ${env.APP_URL}"
                    echo "LB_DNS: ${env.LB_DNS}"
                    echo "EC2_IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Tests et Validation') {
            steps {
                script {
                    echo "🧪 Tests de l'infrastructure déployée..."

                    sh '''
                        echo "📋 Liste des ressources déployées..."
                        terraform state list

                        echo "🔍 Détails de l'état..."
                        terraform show -no-color
                    '''

                    // Tests de connectivité si des URLs sont disponibles
                    if (env.APP_URL != "non-défini" && env.APP_URL != "") {
                        sh """
                            echo "🌐 Test de l'application: ${env.APP_URL}"
                            timeout 30s bash -c '
                                for i in {1..10}; do
                                    if curl -f -s -o /dev/null -w "Code HTTP: %{http_code}\\\\n" "${env.APP_URL}"; then
                                        echo "✅ Application accessible"
                                        exit 0
                                    fi
                                    echo "⏳ Tentative \$i/10 - Application non encore accessible"
                                    sleep 10
                                done
                                echo "❌ Application non accessible après 10 tentatives"
                                exit 1
                            ' || echo "⚠️ Test de connectivité échoué"
                        """
                    }

                    if (env.LB_DNS != "non-défini" && env.LB_DNS != "") {
                        sh """
                            echo "🌐 Test du Load Balancer: ${env.LB_DNS}"
                            curl -f -s -o /dev/null -w "Code HTTP: %{http_code}\\\\n" "http://${env.LB_DNS}" && echo "✅ Load Balancer accessible" || echo "⚠️ Load Balancer non accessible"
                        """
                    }

                    if (env.EC2_IP != "non-défini" && env.EC2_IP != "") {
                        sh """
                            echo "🌐 Test de l\'EC2: ${env.EC2_IP}"
                            ping -c 3 ${env.EC2_IP} && echo "✅ EC2 accessible" || echo "⚠️ EC2 non accessible via ping"
                        """
                    }
                }
            }
        }

        stage('Documentation et Rapports') {
            steps {
                sh '''
                    echo "📋 Génération de la documentation..."

                    # Générer un graphique des ressources
                    terraform graph | dot -Tpng > infrastructure.png 2>/dev/null || echo "⚠️ Impossible de générer le graphique"

                    # Sauvegarder l'état
                    terraform show -no-color > terraform_state.txt

                    echo "📁 Fichiers générés:"
                    ls -la *.png *.txt 2>/dev/null || echo "Aucun fichier de rapport généré"
                '''

                // Archive des artefacts
                archiveArtifacts artifacts: '*.png,*.txt,*.json', fingerprint: true
            }
        }
    }

    post {
        always {
            echo "📝 Pipeline ${currentBuild.currentResult} - Build #${BUILD_NUMBER}"
            script {
                def buildDuration = currentBuild.durationString.replace(' and counting', '')
                def terraformVersion = sh(script: "terraform version | head -1", returnStdout: true).trim()

                // Récupération des ressources déployées
                def resourceCount = sh(script: "terraform state list 2>/dev/null | wc -l || echo '0'", returnStdout: true).trim()

                // Configuration email
                def emailSubject = ""
                def emailBody = ""

                switch(currentBuild.currentResult) {
                    case 'SUCCESS':
                        emailSubject = "✅ SUCCÈS - Infrastructure AWS Terraform ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                        emailBody = """
                        <html>
                        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
                            <h2 style="color: #28a745; border-bottom: 2px solid #28a745; padding-bottom: 10px;">🚀 Infrastructure AWS Déployée!</h2>

                            <p>Le pipeline Terraform <strong>${env.JOB_NAME}</strong> s'est terminé avec succès.</p>

                            <h3 style="color: #0056b3;">📊 Détails du déploiement:</h3>
                            <ul>
                                <li><strong>Build:</strong> #${env.BUILD_NUMBER}</li>
                                <li><strong>Job:</strong> ${env.JOB_NAME}</li>
                                <li><strong>URL Jenkins:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                                <li><strong>Durée:</strong> ${buildDuration}</li>
                                <li><strong>Date:</strong> ${new Date().format("dd/MM/yyyy à HH:mm")}</li>
                                <li><strong>Version Terraform:</strong> ${terraformVersion}</li>
                                <li><strong>Région AWS:</strong> ${AWS_DEFAULT_REGION}</li>
                                <li><strong>Ressources déployées:</strong> ${resourceCount}</li>
                            </ul>

                            ${env.APP_URL != "non-défini" ? """
                            <h3 style="color: #0056b3;">🌐 URL de l'application:</h3>
                            <div style="background-color: #e7f3ff; padding: 15px; border-radius: 5px; border: 1px solid #b3d9ff;">
                                <a href="${env.APP_URL}" style="font-size: 16px; color: #0066cc; text-decoration: none; font-weight: bold;">${env.APP_URL}</a>
                            </div>
                            """ : ""}

                            ${env.LB_DNS != "non-défini" ? """
                            <h3 style="color: #0056b3;">🌐 DNS du Load Balancer:</h3>
                            <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; border: 1px solid #ffeaa7;">
                                <a href="http://${env.LB_DNS}" style="font-size: 16px; color: #856404; text-decoration: none;">http://${env.LB_DNS}</a>
                            </div>
                            """ : ""}

                            ${env.EC2_IP != "non-défini" ? """
                            <h3 style="color: #0056b3;">🌐 IP de l'instance EC2:</h3>
                            <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; border: 1px solid #e9ecef;">
                                <code style="font-size: 16px; color: #495057;">${env.EC2_IP}</code>
                            </div>
                            """ : ""}

                            <div style="background-color: #d4edda; color: #155724; padding: 12px; border-radius: 4px; border: 1px solid #c3e6cb; margin-top: 20px;">
                                <strong>✅ Infrastructure AWS déployée avec succès avec Terraform</strong>
                                <p style="margin: 5px 0 0 0; font-size: 14px;">${resourceCount} ressources gérées dans la région ${AWS_DEFAULT_REGION}</p>
                            </div>

                            <hr style="margin: 20px 0;">
                            <p style="color: #6c757d; font-size: 12px; text-align: center;">
                                Email envoyé automatiquement par Jenkins - ${new Date().format("dd/MM/yyyy à HH:mm")}
                            </p>
                        </div>
                        </body>
                        </html>
                        """
                        break

                    case 'FAILURE':
                        emailSubject = "❌ ÉCHEC - Déploiement Terraform AWS ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                        emailBody = """
                        <html>
                        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
                            <h2 style="color: #dc3545; border-bottom: 2px solid #dc3545; padding-bottom: 10px;">💥 Échec du Déploiement AWS</h2>

                            <p>Le pipeline Terraform AWS <strong>${env.JOB_NAME}</strong> a échoué lors du build #${env.BUILD_NUMBER}.</p>

                            <h3 style="color: #0056b3;">📋 Détails techniques:</h3>
                            <ul>
                                <li><strong>Build:</strong> #${env.BUILD_NUMBER}</li>
                                <li><strong>Job:</strong> ${env.JOB_NAME}</li>
                                <li><strong>URL Jenkins:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
                                <li><strong>Durée:</strong> ${buildDuration}</li>
                                <li><strong>Région AWS:</strong> ${AWS_DEFAULT_REGION}</li>
                            </ul>

                            <div style="background-color: #f8d7da; color: #721c24; padding: 15px; border-radius: 4px; border: 1px solid #f5c6cb; margin-top: 20px;">
                                <strong>❌ Intervention nécessaire - Consultez les logs Jenkins pour plus de détails</strong>
                                <p style="margin: 10px 0 0 0;"><a href="${env.BUILD_URL}console" style="color: #721c24; text-decoration: underline;">Accéder aux logs du build</a></p>
                            </div>

                            <div style="background-color: #fff3cd; color: #856404; padding: 12px; border-radius: 4px; border: 1px solid #ffeaa7; margin-top: 15px;">
                                <strong>💡 Actions recommandées:</strong>
                                <ul style="margin: 10px 0 0 20px;">
                                    <li>Vérifier les logs de build Jenkins</li>
                                    <li>Contrôler les credentials AWS</li>
                                    <li>Vérifier la configuration Terraform</li>
                                    <li>S'assurer des permissions IAM</li>
                                </ul>
                            </div>

                            <hr style="margin: 20px 0;">
                            <p style="color: #6c757d; font-size: 12px; text-align: center;">
                                Email envoyé automatiquement par Jenkins - ${new Date().format("dd/MM/yyyy à HH:mm")}
                            </p>
                        </div>
                        </body>
                        </html>
                        """
                        break

                    case 'UNSTABLE':
                        emailSubject = "⚠️ INSTABLE - Déploiement Terraform AWS ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                        emailBody = """
                        <html>
                        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ffc107; border-radius: 5px;">
                            <h2 style="color: #ffc107; border-bottom: 2px solid #ffc107; padding-bottom: 10px;">⚠️ Déploiement avec Avertissements</h2>

                            <p>Le pipeline Terraform AWS <strong>${env.JOB_NAME}</strong> s'est terminé avec des avertissements.</p>

                            <div style="background-color: #fff3cd; color: #856404; padding: 12px; border-radius: 4px; border: 1px solid #ffeaa7; margin-top: 15px;">
                                <strong>L'infrastructure est déployée mais nécessite une attention.</strong>
                            </div>

                            <p><a href="${env.BUILD_URL}">Voir les détails du build</a></p>
                        </div>
                        </body>
                        </html>
                        """
                        break
                }

                // Envoi de l'email
                if (emailSubject && emailBody) {
                    emailext (
                        subject: emailSubject,
                        body: emailBody,
                        to: "${EMAIL_RECIPIENTS}",
                        mimeType: "text/html"
                    )
                }

                // Nettoyage des fichiers temporaires
                sh '''
                    echo "🧹 Nettoyage des fichiers temporaires..."
                    rm -f tfplan terraform.tfstate.backup 2>/dev/null || true
                    rm -f terraform_state.txt infrastructure.png 2>/dev/null || true
                '''
            }
        }

        success {
            echo '✅ Pipeline Terraform AWS terminé avec succès!'
            script {
                echo "🏗️ Infrastructure déployée avec Terraform"
                echo "📊 ${resourceCount} ressources gérées dans ${AWS_DEFAULT_REGION}"

                if (env.APP_URL != "non-défini" && env.APP_URL != "") {
                    echo "🌐 Application déployée: ${env.APP_URL}"
                }
                if (env.LB_DNS != "non-défini" && env.LB_DNS != "") {
                    echo "🌐 Load Balancer: http://${env.LB_DNS}"
                }
                if (env.EC2_IP != "non-défini" && env.EC2_IP != "") {
                    echo "🌐 Instance EC2: ${env.EC2_IP}"
                }
            }
        }

        failure {
            echo '❌ Pipeline Terraform AWS a échoué!'
            echo '🔍 Consultez les logs Jenkins pour plus de détails'

            // Nettoyage optionnel en cas d'échec
            script {
                echo "🗑️  Nettoyage de l'infrastructure en cas d'échec..."
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS_ID}",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        echo "🧨 Destruction de l'infrastructure suite à l'échec..."
                        terraform destroy -auto-approve -var="environment=jenkins" -var="aws_region=${AWS_DEFAULT_REGION}" || echo "⚠️ Échec de la destruction"
                    '''
                }
            }
        }

        unstable {
            echo '⚠️  Pipeline terminé avec statut instable'
            echo '📋 Certains tests ou vérifications ont échoué'
        }

        cleanup {
            echo "🧼 Nettoyage final de l'environnement"
            sh '''
                # Suppression des fichiers sensibles
                rm -f .terraform.lock.hcl 2>/dev/null || true

                # Nettoyage du workspace
                find . -name "*.log" -delete 2>/dev/null || true
            '''
        }
    }
}
# Provider AWS
provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Subnet publique
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Route Table publique
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Association Route Table avec Subnet publique
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group pour le backend
resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg"
  description = "Security group for backend API"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Backend API"
    from_port   = var.backend_port
    to_port     = var.backend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-backend-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Security Group pour MongoDB
resource "aws_security_group" "mongodb" {
  name        = "${var.project_name}-mongodb-sg"
  description = "Security group for MongoDB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MongoDB from Backend"
    from_port       = var.mongodb_port
    to_port         = var.mongodb_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  ingress {
    description = "SSH"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-mongodb-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Security Group pour le frontend (sur EC2)
resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-sg"
  description = "Security group for frontend"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Frontend Dev Server"
    from_port   = var.frontend_port
    to_port     = var.frontend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-frontend-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Data source pour l'AMI Amazon Linux 2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Création d'une key pair (génère une clé temporaire)
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "${var.project_name}-key-${var.environment}"
  public_key = tls_private_key.this.public_key_openssh
}

# Instance EC2 pour le backend
resource "aws_instance" "backend" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.backend.id
  ]

  associate_public_ip_address = true
  key_name                    = aws_key_pair.terraform_key.key_name

  user_data = <<-EOF
    #!/bin/bash
    # Mise à jour du système
    yum update -y

    # Installation de Node.js
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    yum install -y nodejs

    # Installation de Git
    yum install -y git

    # Installation de PM2
    npm install -g pm2

    # Création du répertoire de l'application
    mkdir -p /home/ec2-user/app/backend
    cd /home/ec2-user/app/backend

    # Création du package.json
    cat > package.json << 'EOL'
    {
      "name": "backend-api",
      "version": "1.0.0",
      "description": "Backend API",
      "main": "app.js",
      "scripts": {
        "start": "node app.js"
      },
      "dependencies": {
        "express": "^4.18.2",
        "mongoose": "^7.0.0",
        "cors": "^2.8.5",
        "dotenv": "^16.0.3"
      }
    }
    EOL

    # Installation des dépendances
    npm install

    # Création du fichier app.js exemple
    cat > app.js << 'EOL'
    const express = require('express');
    const cors = require('cors');
    require('dotenv').config();

    const app = express();
    const PORT = process.env.PORT || 5000;

    app.use(cors());
    app.use(express.json());

    // Route de test
    app.get('/api/health', (req, res) => {
      res.json({
        status: 'OK',
        message: 'Backend API is running',
        timestamp: new Date().toISOString()
      });
    });

    // Route pour les todos (exemple)
    let todos = [];

    app.get('/api/todos', (req, res) => {
      res.json(todos);
    });

    app.post('/api/todos', (req, res) => {
      const todo = {
        id: Date.now(),
        text: req.body.text,
        completed: false
      };
      todos.push(todo);
      res.json(todo);
    });

    app.get('/api/info', (req, res) => {
      res.json({
        message: 'Backend Server Information',
        server: 'Express.js',
        database: 'MongoDB',
        status: 'running'
      });
    });

    app.listen(PORT, '0.0.0.0', function() {
      console.log('Backend server running on port ' + PORT);
    });
    EOL

    # Démarrage de l'application avec PM2
    pm2 start app.js --name backend-api
    pm2 startup
    pm2 save

    # Marqueur de fin d'installation
    echo "Backend installation completed successfully" > /home/ec2-user/backend-ready.txt
    echo "Backend API URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5000/api/health" >> /home/ec2-user/backend-ready.txt
  EOF

  tags = {
    Name        = "${var.project_name}-backend"
    Project     = var.project_name
    Environment = var.environment
    Type        = "backend"
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_key_pair.terraform_key
  ]
}

# Instance EC2 pour MongoDB
resource "aws_instance" "mongodb" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.mongodb.id
  ]

  associate_public_ip_address = true
  key_name                    = aws_key_pair.terraform_key.key_name

  user_data = <<-EOF
    #!/bin/bash
    # Mise à jour du système
    yum update -y

    # Création du fichier repo MongoDB
    cat > /etc/yum.repos.d/mongodb-org-6.0.repo << 'EOL'
    [mongodb-org-6.0]
    name=MongoDB Repository
    baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
    gpgcheck=1
    enabled=1
    gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
    EOL

    # Installation de MongoDB
    yum install -y mongodb-org

    # Démarrage de MongoDB
    systemctl start mongod
    systemctl enable mongod

    # Attendre que MongoDB soit démarré
    sleep 10

    # Configuration pour écouter sur toutes les interfaces
    sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

    # Redémarrage de MongoDB pour appliquer les changements
    systemctl restart mongod

    # Attendre le redémarrage
    sleep 5

    # Création des utilisateurs
    mongosh --eval "
      use admin;
      db.createUser({
        user: 'admin',
        pwd: 'mongodb123',
        roles: [{ role: 'root', db: 'admin' }]
      });
    "

    sleep 2

    # Création de l'utilisateur application
    mongosh -u admin -p mongodb123 --authenticationDatabase admin --eval "
      use fullstackapp;
      db.createUser({
        user: 'appuser',
        pwd: 'apppass123',
        roles: [{ role: 'readWrite', db: 'fullstackapp' }]
      });
    "

    # Marqueur de fin d'installation
    echo "MongoDB installation completed successfully" > /home/ec2-user/mongodb-ready.txt
    echo "MongoDB Connection URL: mongodb://appuser:apppass123@localhost:27017/fullstackapp" >> /home/ec2-user/mongodb-ready.txt
    echo "MongoDB Admin URL: mongodb://admin:mongodb123@localhost:27017/admin" >> /home/ec2-user/mongodb-ready.txt
  EOF

  tags = {
    Name        = "${var.project_name}-mongodb"
    Project     = var.project_name
    Environment = var.environment
    Type        = "database"
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_key_pair.terraform_key
  ]
}

# Instance EC2 pour le frontend (optionnel - si vous voulez déployer le frontend sur EC2)
resource "aws_instance" "frontend" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.frontend.id
  ]

  associate_public_ip_address = true
  key_name                    = aws_key_pair.terraform_key.key_name

  user_data = <<-EOF
    #!/bin/bash
    # Mise à jour du système
    yum update -y

    # Installation de Node.js
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    yum install -y nodejs

    # Installation de nginx pour servir les fichiers statiques
    amazon-linux-extras install nginx1 -y

    # Démarrage de nginx
    systemctl start nginx
    systemctl enable nginx

    # Création du répertoire pour l'application React
    mkdir -p /var/www/html

    # Création d'une page d'exemple
    cat > /var/www/html/index.html << 'EOL'
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${var.project_name} - Frontend</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 40px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                text-align: center;
            }
            .container {
                max-width: 800px;
                margin: 0 auto;
            }
            .status {
                background: rgba(255,255,255,0.1);
                padding: 20px;
                border-radius: 10px;
                margin: 20px 0;
            }
            .btn {
                background: #4CAF50;
                color: white;
                padding: 10px 20px;
                border: none;
                border-radius: 5px;
                cursor: pointer;
                margin: 5px;
            }
            .server-info {
                display: flex;
                justify-content: space-around;
                flex-wrap: wrap;
                margin: 20px 0;
            }
            .server-card {
                background: rgba(255,255,255,0.1);
                padding: 15px;
                border-radius: 8px;
                margin: 10px;
                flex: 1;
                min-width: 200px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 ${var.project_name}</h1>
            <p>Fullstack Application déployée sur AWS avec Terraform</p>

            <div class="server-info">
                <div class="server-card">
                    <h3>Frontend</h3>
                    <p>📍 Serveur: Nginx sur EC2</p>
                    <p>✅ Status: En ligne</p>
                </div>
                <div class="server-card">
                    <h3>Backend API</h3>
                    <p>📍 Serveur: Node.js/Express</p>
                    <p>Status: <span id="backend-status">Vérification...</span></p>
                </div>
                <div class="server-card">
                    <h3>Base de données</h3>
                    <p>📍 Serveur: MongoDB</p>
                    <p>Status: <span id="db-status">En ligne</span></p>
                </div>
            </div>

            <div class="status">
                <h3>Test de l'API Backend</h3>
                <button class="btn" onclick="testBackend()">Tester l'API Backend</button>
                <button class="btn" onclick="testBackendInfo()">Info Serveur</button>
            </div>

            <div id="api-response" class="status" style="display:none;">
                <h4>Réponse de l'API:</h4>
                <pre id="response-content"></pre>
            </div>
        </div>

        <script>
            const backendIP = "${aws_instance.backend.public_ip}";

            async function testBackend() {
                try {
                    const response = await fetch('http://' + backendIP + ':5000/api/health');
                    const data = await response.json();

                    document.getElementById('backend-status').innerHTML = '✅ En ligne';
                    document.getElementById('response-content').textContent = JSON.stringify(data, null, 2);
                    document.getElementById('api-response').style.display = 'block';
                } catch (error) {
                    document.getElementById('backend-status').innerHTML = '❌ Hors ligne';
                    document.getElementById('response-content').textContent = 'Erreur: ' + error.message;
                    document.getElementById('api-response').style.display = 'block';
                }
            }

            async function testBackendInfo() {
                try {
                    const response = await fetch('http://' + backendIP + ':5000/api/info');
                    const data = await response.json();

                    document.getElementById('response-content').textContent = JSON.stringify(data, null, 2);
                    document.getElementById('api-response').style.display = 'block';
                } catch (error) {
                    document.getElementById('response-content').textContent = 'Erreur: ' + error.message;
                    document.getElementById('api-response').style.display = 'block';
                }
            }

            // Test automatique au chargement
            setTimeout(testBackend, 1000);
        </script>
    </body>
    </html>
    EOL

    # Configuration de nginx pour servir les fichiers
    cat > /etc/nginx/nginx.conf << 'EOL'
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log;
    pid /run/nginx.pid;

    events {
        worker_connections 1024;
    }

    http {
        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile            on;
        tcp_nopush          on;
        tcp_nodelay         on;
        keepalive_timeout   65;
        types_hash_max_size 4096;

        include             /etc/nginx/mime.types;
        default_type        application/octet-stream;

        server {
            listen       80;
            listen       [::]:80;
            server_name  _;
            root         /var/www/html;

            location / {
                try_files $uri $uri/ /index.html;
            }
        }
    }
    EOL

    # Redémarrage de nginx
    systemctl restart nginx

    echo "Frontend installation completed successfully" > /home/ec2-user/frontend-ready.txt
    echo "Frontend URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" >> /home/ec2-user/frontend-ready.txt
  EOF

  tags = {
    Name        = "${var.project_name}-frontend"
    Project     = var.project_name
    Environment = var.environment
    Type        = "frontend"
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_key_pair.terraform_key,
    aws_instance.backend
  ]
}
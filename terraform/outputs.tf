output "backend_public_ip" {
  description = "IP publique de l'instance backend"
  value       = aws_instance.backend.public_ip
}

output "frontend_public_ip" {
  description = "IP publique de l'instance frontend"
  value       = aws_instance.frontend.public_ip
}

output "mongodb_private_ip" {
  description = "IP privée de l'instance MongoDB"
  value       = aws_instance.mongodb.private_ip
}

output "backend_api_url" {
  description = "URL de l'API backend"
  value       = "http://${aws_instance.backend.public_ip}:${var.backend_port}"
}

output "frontend_url" {
  description = "URL du frontend"
  value       = "http://${aws_instance.frontend.public_ip}"
}

output "mongodb_connection_string" {
  description = "String de connexion MongoDB"
  value       = "mongodb://appuser:apppass123@${aws_instance.mongodb.private_ip}:27017/fullstackapp"
}

output "ssh_private_key" {
  description = "Clé privée SSH pour se connecter aux instances"
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}

output "ssh_connection_backend" {
  description = "Commande SSH pour se connecter au backend"
  value       = "ssh -i terraform-key.pem ec2-user@${aws_instance.backend.public_ip}"
}

output "ssh_connection_frontend" {
  description = "Commande SSH pour se connecter au frontend"
  value       = "ssh -i terraform-key.pem ec2-user@${aws_instance.frontend.public_ip}"
}

output "ssh_connection_mongodb" {
  description = "Commande SSH pour se connecter à MongoDB"
  value       = "ssh -i terraform-key.pem ec2-user@${aws_instance.mongodb.public_ip}"
}

output "application_summary" {
  description = "Résumé de l'application déployée"
  value       = <<EOT
🎉 Application Fullstack déployée avec succès !

Frontend (React): http://${aws_instance.frontend.public_ip}
Backend API (Express): http://${aws_instance.backend.public_ip}:5000
Base de données: MongoDB sur ${aws_instance.mongodb.private_ip}:27017

Commandes SSH:
- Backend: ssh -i terraform-key.pem ec2-user@${aws_instance.backend.public_ip}
- Frontend: ssh -i terraform-key.pem ec2-user@${aws_instance.frontend.public_ip}
- MongoDB: ssh -i terraform-key.pem ec2-user@${aws_instance.mongodb.public_ip}

Testez l'application en visitant le frontend !
EOT
}
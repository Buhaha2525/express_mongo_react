variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "fullstack-app"
}

variable "environment" {
  description = "Environnement"
  type        = string
  default     = "dev"
}

variable "backend_port" {
  description = "Port du backend Express"
  type        = number
  default     = 5000
}

variable "frontend_port" {
  description = "Port du frontend React"
  type        = number
  default     = 3000
}

variable "mongodb_port" {
  description = "Port MongoDB"
  type        = number
  default     = 27017
}

variable "ssh_port" {
  description = "Port SSH"
  type        = number
  default     = 22
}
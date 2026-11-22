variable "aws_region" {
  description = "Region de AWS donde se crea todo"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefijo para nombrar los recursos"
  type        = string
  default     = "aguafix"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Llave publica SSH que se registra en el key pair"
  type        = string
  default     = "~/.ssh/aguafix_ed25519.pub"
}

variable "ssh_allowed_cidr" {
  description = "Desde donde se permite SSH (GitHub Actions necesita entrar)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "docker_image" {
  description = "Imagen de la API en Docker Hub"
  type        = string
  default     = "leogoma/water-reports-api:latest"
}

variable "bucket_name" {
  description = "Nombre del bucket de S3 para las fotos (unico en todo AWS)"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "waterreportsdb"
}

variable "db_user" {
  description = "Usuario de PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Contrasena de PostgreSQL"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && !strcontains(var.db_password, "'")
    error_message = "db_password debe tener al menos 8 caracteres y no llevar comillas simples (rompen el .env del servidor)."
  }
}

variable "mailer_service" {
  description = "Servicio de correo de nodemailer"
  type        = string
  default     = "gmail"
}

variable "mailer_user" {
  description = "Cuenta que envia los correos"
  type        = string
  sensitive   = true
}

variable "mailer_token" {
  description = "App password de la cuenta de correo"
  type        = string
  sensitive   = true
}

variable "mailer_crew" {
  description = "Correo de la cuadrilla que recibe los avisos"
  type        = string
}

variable "noip_username" {
  description = "Usuario (o correo) de No-IP"
  type        = string
  sensitive   = true
}

variable "noip_password" {
  description = "Contrasena de No-IP"
  type        = string
  sensitive   = true
}

variable "noip_hostname" {
  description = "Hostname creado en noip.com, por ejemplo aguafix.ddns.net"
  type        = string
  sensitive   = true
}

output "public_ip" {
  description = "IP publica de la EC2"
  value       = aws_instance.api.public_ip
}

# El hostname es variable sensitive; aqui se muestra porque es la URL publica de la API.
output "api_url" {
  description = "URL de la API con el dominio de No-IP"
  value       = nonsensitive("http://${var.noip_hostname}/")
}

output "api_url_ip" {
  description = "URL de la API por IP, por si el dominio aun no se actualiza"
  value       = "http://${aws_instance.api.public_ip}/"
}

output "ssh_command" {
  description = "Comando para entrar al servidor"
  value       = "ssh -i ${trimsuffix(var.public_key_path, ".pub")} ubuntu@${aws_instance.api.public_ip}"
}

output "bucket_name" {
  description = "Bucket de las fotos"
  value       = aws_s3_bucket.photos.bucket
}

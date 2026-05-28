output "windows_public_ip" {
  description = "IP publico para conexao RDP"
  value       = module.windows_server.public_ip
}

output "windows_private_ip" {
  description = "IP privado da instancia"
  value       = module.windows_server.private_ip
}

output "s3_bucket" {
  description = "Nome do bucket S3"
  value       = module.s3.bucket_id
}

output "rdp_command" {
  description = "Comando para conectar via RDP"
  value       = "mstsc /v:${module.windows_server.public_ip}"
}

output "get_password" {
  description = "Comando para decryptar a senha do Windows"
  value       = "aws ec2 get-password-data --instance-id ${module.windows_server.instance_id} --priv-launch-key ~/windows-ad-key.pem"
}

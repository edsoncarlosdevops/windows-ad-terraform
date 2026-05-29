output "windows_instance_id" {
  description = "Windows EC2 instance ID"
  value       = module.windows_server.instance_id
}

output "windows_public_ip" {
  description = "Public IP for RDP connection"
  value       = module.windows_server.public_ip
}

output "windows_private_ip" {
  description = "Private IP of the instance"
  value       = module.windows_server.private_ip
}

output "windows_rdp_command" {
  description = "RDP connection command"
  value       = "mstsc /v:${module.windows_server.public_ip}"
}

output "windows_password_command" {
  description = "Command to retrieve Administrator password"
  value       = "aws ec2 get-password-data --instance-id ${module.windows_server.instance_id} --priv-launch-key ${path.module}/windows-ad-key.pem"
}

output "windows_login_hint" {
  description = "Default login credentials"
  value       = "User: Administrator | Password: Admin@12345"
}

output "s3_bucket" {
  description = "S3 bucket name"
  value       = module.s3.bucket_id
}

output "rdp_command" {
  description = "RDP connection command"
  value       = "mstsc /v:${module.windows_server.public_ip}"
}

output "get_password" {
  description = "Command to decrypt Windows password"
  value       = "aws ec2 get-password-data --instance-id ${module.windows_server.instance_id} --priv-launch-key ${path.module}/windows-ad-key.pem"
}


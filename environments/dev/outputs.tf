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

output "rdp_command" {
  description = "RDP connection command"
  value       = "mstsc /v:${module.windows_server.public_ip}"
}

output "username" {
  description = "Administrator username for RDP login"
  value       = "${"."}\\Administrator"
}

output "admin_password" {
  description = "Administrator password. Run: terraform output admin_password"
  value       = random_password.admin.result
  sensitive   = true
}

output "s3_bucket" {
  description = "S3 bucket name"
  value       = module.s3.bucket_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}


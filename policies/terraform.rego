package terraform

# Nao permitir security group liberando tudo (0.0.0.0/0)
deny[msg] {
  resource := input.resource.aws_security_group[_]
  ingress := resource.config.ingress[_]
  ingress.cidr_blocks[_] == "0.0.0.0/0"
  msg := sprintf("Security group %v liberando acesso irrestrito (0.0.0.0/0)", [resource.name])
}

# Exigir que S3 tenha encryption
deny[msg] {
  resource := input.resource.aws_s3_bucket[_]
  not input.resource.aws_s3_bucket_server_side_encryption_configuration[_]
  msg := sprintf("Bucket %v sem encryption habilitada", [resource.name])
}

# ---- VPC (default para simplificar) ----
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---- S3 ----
module "s3" {
  source = "../../modules/s3"

  environment = "dev"
  bucket_name = "windows-ad-scripts-${data.aws_vpc.default.id}"
}

# ---- Security Group ----
# ATENCAO: Em producao, trocar allowed_rdp_cidr pelo IP do seu office/VPN
module "security_group" {
  source = "../../modules/security-group"

  environment      = "dev"
  vpc_id           = data.aws_vpc.default.id
  allowed_rdp_cidr = "0.0.0.0/0" # Apenas para dev!
}

# ---- Windows Server ----
resource "random_password" "admin" {
  length  = 16
  special = false
}

module "windows_server" {
  source = "../../modules/windows-server"

  environment       = "dev"
  subnet_id         = data.aws_subnets.default.ids[0]
  security_group_id = module.security_group.security_group_id
  admin_password    = random_password.admin.result
  instance_type     = "t3.large"
}

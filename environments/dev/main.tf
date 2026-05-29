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

# ---- Meu IP publico (dinamico) ----
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

# ---- S3 ----
module "s3" {
  source = "../../modules/s3"

  environment = "dev"
  bucket_name = "windows-ad-scripts-${data.aws_vpc.default.id}"
}

# ---- Security Group ----
module "security_group" {
  source = "../../modules/security-group"

  environment      = "dev"
  vpc_id           = data.aws_vpc.default.id
  allowed_rdp_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

# ---- Windows Server ----
resource "random_password" "admin" {
  length           = 16
  special          = true
  override_special = "!_#-"
  min_special      = 2
}

resource "random_string" "key_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "tls_private_key" "windows_admin" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "windows_admin" {
  key_name   = "windows-ad-${random_string.key_suffix.result}"
  public_key = tls_private_key.windows_admin.public_key_openssh
}

resource "local_file" "windows_admin_pem" {
  content         = tls_private_key.windows_admin.private_key_pem
  filename        = "${path.module}/windows-ad-key.pem"
  file_permission = "0600"
}

module "windows_server" {
  source = "../../modules/windows-server"

  environment       = "dev"
  subnet_id         = data.aws_subnets.default.ids[0]
  security_group_id = module.security_group.security_group_id
# ---- VPC ----
module "vpc" {
  source = "../../modules/vpc"

  environment = "dev"
}

# ---- Meu IP publico (dinamico) ----
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

# ---- S3 ----
module "s3" {
  source = "../../modules/s3"

  environment = "dev"
  bucket_name = "windows-ad-scripts-${module.vpc.vpc_id}"
}

# ---- Security Group ----
module "security_group" {
  source = "../../modules/security-group"

  environment      = "dev"
  vpc_id           = module.vpc.vpc_id
  allowed_rdp_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

# ---- Windows Server ----
resource "random_password" "admin" {
  length           = 16
  special          = true
  override_special = "!_#-"
  min_special      = 2
}

resource "random_string" "key_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "tls_private_key" "windows_admin" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "windows_admin" {
  key_name   = "windows-ad-${random_string.key_suffix.result}"
  public_key = tls_private_key.windows_admin.public_key_openssh
}

resource "local_file" "windows_admin_pem" {
  content         = tls_private_key.windows_admin.private_key_pem
  filename        = "${path.module}/windows-ad-key.pem"
  file_permission = "0600"
}

module "windows_server" {
  source = "../../modules/windows-server"

  environment       = "dev"
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_group.security_group_id
  admin_password    = "Admin@12345"
  instance_type     = "t3.large"
  key_name          = aws_key_pair.windows_admin.key_name
}
  instance_type     = "t3.large"
  key_name          = aws_key_pair.windows_admin.key_name
}


resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "state" {
  bucket        = "terraform-state-windows-ad-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Atualiza o provider.tf do dev com o nome do bucket criado
resource "local_file" "update_dev_provider" {
  content  = <<-EOT
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
  
  }

  backend "s3" {
    bucket = "${aws_s3_bucket.state.bucket}"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}
EOT
  filename = "${path.module}/../dev/provider.tf"
}


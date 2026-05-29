resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# NOTE: force_destroy is enabled for this test/development environment.
# In production, set force_destroy = false and add lifecycle.prevent_destroy = true
# to protect the Terraform state bucket from accidental deletion.
resource "aws_s3_bucket" "state" {
  bucket        = "terraform-state-windows-ad-${random_string.suffix.result}"
  force_destroy = true
  tags = {
    Name        = "terraform-state-windows-ad"
    Environment = "bootstrap"
    ManagedBy   = "terraform"
    Project     = "windows-ad-terraform"
  }
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
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
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



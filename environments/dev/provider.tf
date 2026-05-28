# ATENCAO: Antes de rodar terraform init aqui, execute:
# 1. cd environments/stage-1 && terraform init && terraform apply
# 2. Copie o bucket_name do output
# 3. Cole no backend abaixo

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
  }

  backend "s3" {
    bucket = "SUBSTITUA_PELO_NOME_DO_BUCKET"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

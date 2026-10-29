terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State remoto no S3 (bucket criado na Aula 08).
  # O nome do bucket NÃO fica no código: o workflow passa
  #   terraform init -backend-config="bucket=<secret TF_STATE_BUCKET>"
  backend "s3" {
    key    = "aula-10/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28.0"
    }
  }

  backend "s3" {
    bucket         = "chaitanya-project-remote-state-bucket"
    key            = "k8-eksctl"
    region         = "us-east-1"
    dynamodb_table = "chaitanya-locking"
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

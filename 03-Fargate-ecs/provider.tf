# provider.tf

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~>2.20.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0" # You can specify a version here or adjust based on the latest version.
    }
  }
}

# Specify the provider and access details
provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "random" {}

resource "random_pet" "suffix" {
  length = 2
}

locals {
  app_name = "helix-smoke-${random_pet.suffix.id}"
  tags = {
    env   = "dev"
    owner = "helix-tests"
  }
}

output "app_name" {
  value = local.app_name
}

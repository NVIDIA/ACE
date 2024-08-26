
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.57.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.4.3"
    }
  }
  required_version = "= 1.2.4"
}

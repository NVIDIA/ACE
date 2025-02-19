provider "aws" {
  region     = var.region
  access_key = var.provider_config.access_key
  secret_key = var.provider_config.secret_key
}

provider "aws" {
  region     = "us-east-1"
  alias      = "cloudfront"
  access_key = var.provider_config.access_key
  secret_key = var.provider_config.secret_key
}
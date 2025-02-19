
provider "aws" {
  region     = var.provider_config.region
  access_key = var.provider_config.access_key
  secret_key = var.provider_config.secret_key
}

# fixed region for cloudfront certs
provider "aws" {
  region     = "us-east-1"
  alias      = "cloudfront"
  access_key = var.provider_config.access_key
  secret_key = var.provider_config.secret_key
}
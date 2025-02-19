
provider "google" {
  project     = var.provider_config.project
  credentials = var.provider_config.credentials
}
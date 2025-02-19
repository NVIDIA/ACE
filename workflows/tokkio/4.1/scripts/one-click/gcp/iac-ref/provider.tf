provider "google" {
  region      = var.region
  project     = var.provider_config.project
  credentials = var.provider_config.credentials
}

provider "google-beta" {
  region      = var.region
  project     = var.provider_config.project
  credentials = var.provider_config.credentials
}

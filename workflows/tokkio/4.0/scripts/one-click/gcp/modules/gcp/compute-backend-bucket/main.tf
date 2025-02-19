
resource "google_compute_backend_bucket" "this" {
  name             = format("%s-backend", var.name)
  bucket_name      = var.bucket_name
  enable_cdn       = var.enable_cdn
  compression_mode = var.compression_mode
}
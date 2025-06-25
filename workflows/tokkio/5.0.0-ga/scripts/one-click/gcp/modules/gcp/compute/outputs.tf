output "instance" {
  value       = google_compute_instance.default
  description = "The outputs of the instance"
}

output "private_ip" {
  value = try(google_compute_instance.default.network_interface[0].network_ip, null)
}

output "public_ip" {
  value = try(google_compute_instance.default.network_interface[0].access_config[0].nat_ip, null)
}

output "public_ip" {
  value = one([
    for access_config in flatten([
      for network_interface in google_compute_instance.this.network_interface : network_interface["access_config"]
    ]) : access_config["nat_ip"]
  ])
}
output "private_ip" {
  value = one([
    for network_interface in google_compute_instance.this.network_interface : network_interface["network_ip"]
  ])
}
output "self_link" {
  value = google_compute_instance.this.self_link
}
output "zone" {
  value = google_compute_instance.this.zone
}
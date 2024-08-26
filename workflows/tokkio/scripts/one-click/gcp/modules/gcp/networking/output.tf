
output "network_name" {
  value = google_compute_network.this.name
}
output "subnetworks" {
  value = {
    for subnet in var.subnets : subnet.name => {
      name    = google_compute_subnetwork.this[subnet.name].name
      private = subnet.private
    }
  }
}
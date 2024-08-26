
resource "google_compute_instance_group" "this" {
  name      = var.name
  zone      = var.zone
  instances = var.instance_self_links
  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = named_port.value["name"]
      port = named_port.value["port"]
    }
  }
}
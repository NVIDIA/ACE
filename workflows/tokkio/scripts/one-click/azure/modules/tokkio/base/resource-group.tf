
module "resource_group" {
  source = "../../azure/resource-group"
  name   = var.name
  region = var.region
}
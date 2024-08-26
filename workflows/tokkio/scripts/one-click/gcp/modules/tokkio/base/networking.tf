
module "networking" {
  source     = "../../gcp/networking"
  name       = local.networking.name
  region     = local.networking.region
  subnets    = local.networking.subnets
  router_bgp = local.networking.router_bgp
  firewalls  = local.networking.firewalls
}
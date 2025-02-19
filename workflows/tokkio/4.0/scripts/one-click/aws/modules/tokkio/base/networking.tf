
module "networking" {
  source               = "../../aws/networking"
  cidr_block           = var.cidr_block
  vpc_name             = format("%s-vpc", var.name)
  public_subnet_names  = [for i in range(1, 3) : format("%s-pub-%s", var.name, i)]
  private_subnet_names = [for i in range(1, 3) : format("%s-prv-%s", var.name, i)]
}
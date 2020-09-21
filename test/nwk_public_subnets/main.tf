provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source           = "../../"
  name             = var.name
  vpc_cidr         = var.vpc_cidr
  subnets_byname   = var.subnets_byname
  public_subnets   = [var.public_subnet]
  operating_system = "windows"
}

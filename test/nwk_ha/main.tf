provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source             = "../../"
  name               = var.name
  vpc_cidr           = var.vpc_cidr
  subnets_byname     = var.subnets_byname
  public_subnets     = var.public_subnets
  availability_zone  = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  enable_nat_gateway = true
}

output "vpc_id" {
  value = module.nwk.vpc_id
}

output "subnet_ids" {
  value = module.nwk.subnet_ids
}

provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source         = "../../"
  name           = var.name
  vpc_cidr       = var.vpc_cidr
  subnets_byname = var.subnets_byname
}

output "vpc_id" {
  value = module.nwk.vpc.id
}
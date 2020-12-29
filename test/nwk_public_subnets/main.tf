provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source            = "../../"
  name              = var.name
  vpc_cidr          = var.vpc_cidr
  subnets_byname    = var.subnets_byname
  public_subnets    = [var.public_subnet]
  availability_zone = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

output "vpc" {
  value = module.nwk.vpc_id
}

output "public_subnet" {
  value = module.nwk.subnets[var.public_subnet].id
}

output "subnetmap" {
  value = module.nwk.subnetmap
}

provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source            = "../../"
  name              = var.name
  vpc_cidr          = var.vpc_cidr
  subnets_byname    = var.subnets_byname
  availability_zone = ["eu-north-1a"]
}

output "vpc_id" {
  value = module.nwk.vpc_id
}

output "subnet_ids" {
  value = module.nwk.subnet_ids
}

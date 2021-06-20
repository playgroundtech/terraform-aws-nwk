provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source            = "../../"
  name              = var.name
  vpc_cidr          = var.vpc_cidr
  subnets_bybits    = [{ name = "App", bits = 1, net = 1 }, { name = "Front", bits = 2, net = 1 }, { name = "DB", bits = 3, net = 1 }, { name = "Admin", bits = 3, net = 0 }]
  availability_zone = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

output "vpc_id" {
  value = module.nwk.vpc_id
}
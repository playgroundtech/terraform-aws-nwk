provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source            = "../../"
  name              = var.name
  vpc_cidr          = var.vpc_cidr
  subnets_bycidr    = [{ name = "App", cidr = "10.0.0.128/26" }, { name = "Front", cidr = "10.0.0.64/26" }, { name = "DB", cidr = "10.0.0.32/27" }, { name = "Admin", cidr = "10.0.0.0/27" }]
  availability_zone = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

output "vpc" {
  value = module.nwk.vpc_id
}

output "subnetmap" {
  value = module.nwk.subnetmap
}
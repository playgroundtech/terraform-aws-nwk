provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source             = "../../"
  name               = var.name
  vpc_cidr           = var.vpc_cidr
  subnets_byname     = var.subnets_byname
  public_subnets     = [var.public_subnet]
  availability_zone  = ["eu-north-1a", "eu-north-1b"]
  enable_nat_gateway = false
  default_network_acl_ingress = [
    {
      rule_no    = 100
      action     = "deny"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no         = 101
      action          = "deny"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
  default_network_acl_egress = [
    {
      rule_no    = 100
      action     = "deny"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no         = 101
      action          = "deny"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
}

output "vpc_id" {
  value = module.nwk.vpc_id
}

output "public_subnet" {
  value = module.nwk.subnets[var.public_subnet].id
}

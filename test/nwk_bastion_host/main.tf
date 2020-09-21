provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source           = "../../"
  name             = var.name
  vpc_cidr         = var.vpc_cidr
  subnets_byname   = var.subnets_byname
  bastion_subnets  = [var.bastion_subnets]
  operating_system = var.operating_system
}

resource "aws_instance" "test" {
  ami                    = "ami-0e769fbef3dc1c3b8"
  instance_type          = "t3.micro"
  key_name               = var.key_pair_name
  subnet_id              = module.nwk.subnets[var.bastion_subnets].id
  vpc_security_group_ids = [module.nwk.security_groups[var.bastion_subnets].id]
}

output "vpc_id" {
  value = module.nwk.vpc.id
}

output "public_instance_ip" {
  value = aws_instance.test.public_ip
}

output "bastion_subnet" {
  value = module.nwk.subnets[var.bastion_subnets].id
}
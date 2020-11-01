provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source            = "../../"
  name              = var.name
  vpc_cidr          = var.vpc_cidr
  subnets_byname    = var.subnets_byname
  bastion_subnets   = [var.bastion_subnets]
  availability_zone = ["eu-north-1a"]
}

resource "aws_instance" "test" {
  ami                    = "ami-0e769fbef3dc1c3b8"
  instance_type          = "t3.micro"
  key_name               = var.key_pair_name
  subnet_id              = module.nwk.subnets[var.bastion_subnets].id
  vpc_security_group_ids = [aws_security_group.sg.id]
}
resource "aws_security_group" "sg" {
  name        = "BastionHost"
  description = "Security Group for allowing ssh to Bastion Host"
  vpc_id      = module.nwk.vpc.id
}

resource "aws_security_group_rule" "sgr" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.sg.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
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
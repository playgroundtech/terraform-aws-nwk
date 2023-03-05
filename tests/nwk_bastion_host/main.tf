provider "aws" {
  region = "eu-north-1"
}

module "nwk" {
  source            = "../../"
  name              = var.name
  vpc_cidr          = var.vpc_cidr
  subnets_byname    = var.subnets_byname
  public_subnets    = [var.public_subnets]
  availability_zone = ["eu-north-1a"]
}

#Ignore the rule. Intentionally done for testing.
#tfsec:ignore:aws-ec2-enforce-http-token-imds
resource "aws_instance" "test" {
  ami                    = "ami-0e769fbef3dc1c3b8"
  instance_type          = "t3.micro"
  key_name               = var.key_pair_name
  subnet_id              = module.nwk.subnets[var.public_subnets].id
  vpc_security_group_ids = [aws_security_group.sg.id]

  root_block_device {
    encrypted = true
  }
}
resource "aws_security_group" "sg" {
  name        = "BastionHost"
  description = "Security Group for allowing ssh to Bastion Host"
  vpc_id      = module.nwk.vpc.id
}

#Ignore the rule for allowing ssh from 0.0.0.0/0. Intentionally done for testing.
#tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group_rule" "sgr" {
  security_group_id = aws_security_group.sg.id
  description       = "Terratest SG Rule"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

output "vpc_id" {
  value = module.nwk.vpc_id
}

output "public_instance_ip" {
  value = aws_instance.test.public_ip
}

output "bastion_subnet" {
  value = module.nwk.subnets[var.public_subnets].id
}

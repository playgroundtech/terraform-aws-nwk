resource "aws_security_group_rule" "public_webhost_ingress" {
  for_each = local.public_subnets
  type = "ingress"
  from_port = 443
  protocol = "tcp"
  security_group_id = aws_security_group.security_group[each.key].id
  to_port = 443
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "public_webhost_egress" {
  for_each = local.public_subnets
  type = "egress"
  from_port = 443
  protocol = "tcp"
  security_group_id = aws_security_group.security_group[each.key].id
  to_port = 443
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_ingress" {
  for_each = var.operating_system == "" ? {} : local.bastion_subnets
  from_port = var.operating_system == "linux" ? 22 : var.operating_system == "windows" ? 443 : null
  protocol = "tcp"
  security_group_id = aws_security_group.security_group[each.key].id
  to_port = var.operating_system == "linux" ? 22 : var.operating_system == "windows" ? 443 : null
  type = "ingress"
  cidr_blocks = var.bastion_cidr_blocks
}

resource "aws_security_group_rule" "internal_rdp_ingress" {
  for_each = var.operating_system == "linux" || var.operating_system == "" ? {} : local.subnetmap
  type = "ingress"
  from_port = 3389
  protocol = "tcp"
  security_group_id = aws_security_group.security_group[each.key].id
  to_port = 3389
  cidr_blocks = [aws_vpc.main.cidr_block]
}

resource "aws_security_group_rule" "internal_rdp_egress" {
  for_each = var.operating_system == "linux" || var.operating_system == "" ? {} : local.subnetmap
  type = "egress"
  from_port = 3389
  protocol = "tcp"
  security_group_id = aws_security_group.security_group[each.key].id
  to_port = 3389
  cidr_blocks = [aws_vpc.main.cidr_block]
}

resource "aws_security_group_rule" "internal_ssh_ingress" {
  for_each = var.operating_system == "windows" || var.operating_system == "" ? {} : local.subnetmap
  type = "ingress"
  from_port = 22
  protocol = "tcp"
  security_group_id = aws_security_group.security_group[each.key].id
  to_port = 22
  cidr_blocks = [aws_vpc.main.cidr_block]
}

resource "aws_security_group_rule" "internal_ssh_egress" {
  for_each = var.operating_system == "windows" || var.operating_system == "" ? {} : local.subnetmap
  type = "egress"
  from_port = 22
  protocol = "tcp"
  security_group_id = aws_security_group.security_group[each.key].id
  to_port = 22
  cidr_blocks = [aws_vpc.main.cidr_block]
}

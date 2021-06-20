resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id
  subnet_ids             = [for subnets in aws_subnet.subnets : subnets.id]

  dynamic "ingress" {
    for_each = var.default_network_acl_ingress
    content {
      rule_no         = ingress.value.rule_no
      protocol        = ingress.value.protocol
      action          = ingress.value.action
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      cidr_block      = lookup(ingress.value, "cidr_block", null)
      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
      icmp_code       = lookup(ingress.value, "icmp_code", null)
      icmp_type       = lookup(ingress.value, "icmp_type", null)
    }
  }

  dynamic "egress" {
    for_each = var.default_network_acl_egress
    content {
      rule_no         = egress.value.rule_no
      protocol        = egress.value.protocol
      action          = egress.value.action
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      cidr_block      = lookup(egress.value, "cidr_block", null)
      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
      icmp_code       = lookup(egress.value, "icmp_code", null)
      icmp_type       = lookup(egress.value, "icmp_type", null)
    }
  }

  tags = merge(
    {
      "Name" = format("%s-default-nacl", var.name)
    },
    var.vpc_tags
  )
}

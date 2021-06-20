locals {
  subnet_bits = var.subnet_bits == -1 ? 3 : var.subnet_bits
  subnet_to_map = tomap(merge(
    { for subnet in var.subnets_byname : subnet => { cidr = cidrsubnet(var.vpc_cidr, local.subnet_bits, index(var.subnets_byname, subnet)), az = element(var.availability_zone, index(var.subnets_byname, subnet)) } },
    { for subnet in var.subnets_bybits : subnet.name => { cidr = cidrsubnet(var.vpc_cidr, subnet.bits, subnet.net), az = element(var.availability_zone, index(var.subnets_bybits, subnet)) } },
    { for subnet in var.subnets_bycidr : subnet.name => { cidr = subnet.cidr, az = element(var.availability_zone, index(var.subnets_bycidr, subnet)) } },
  ))
  public_subnets     = { for net in keys(local.subnet_to_map) : net => net if contains(var.public_subnets, net) == true }
  non_public_subnets = { for net in keys(local.subnet_to_map) : net => net if contains(var.public_subnets, net) != true }
}
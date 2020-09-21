locals {
  subnetaddbits = var.subnet_bits == -1 ? 3 : var.subnet_bits
  subnetmap = tomap(merge(
    { for subnet in var.subnets_byname : subnet => { cidr = cidrsubnet(var.vpc_cidr, local.subnetaddbits, index(var.subnets_byname, subnet)) } },
    { for subnet in var.subnets_bybits : subnet.name => { cidr = cidrsubnet(var.vpc_cidr, subnet.bits, subnet.net) } },
    { for subnet in var.subnets_bycidr : subnet.name => { cidr = subnet.cidr } },
  ))
  subnets_without_stdsg = { for net in keys(local.subnetmap) : net => net if contains(var.subnets_without_stdsg, net) != true }
  public_subnets        = { for net in keys(local.subnets_without_stdsg) : net => net if contains(var.public_subnets, net) == true }
  bastion_subnets       = { for net in keys(local.subnets_without_stdsg) : net => net if contains(var.bastion_subnets, net) == true }
  non_public_subnets    = { for net in keys(local.subnets_without_stdsg) : net => net if contains(var.public_subnets, net) != true }
}
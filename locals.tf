locals {
  subnet_bits = var.subnet_bits == -1 ? 3 : var.subnet_bits
  subnet_to_map = tomap(merge(
    { for subnet in var.subnets_byname : subnet =>
      {
        cidr = cidrsubnet(var.vpc_cidr, local.subnet_bits, index(var.subnets_byname, subnet)),
        az   = element(var.availability_zone, index(var.subnets_byname, subnet))
      }
    },
    { for subnet in var.subnets_bybits : subnet.name =>
      {
        cidr = cidrsubnet(var.vpc_cidr, subnet.bits, subnet.net),
        az   = element(var.availability_zone, index(var.subnets_bybits, subnet))
      }
    },
    { for subnet in var.subnets_bycidr : subnet.name =>
      {
        cidr = subnet.cidr,
        az   = element(var.availability_zone, index(var.subnets_bycidr, subnet))
      }
    },
  ))
  public_subnets     = { for net in keys(local.subnet_to_map) : net => net if contains(var.public_subnets, net) == true }
  non_public_subnets = { for net in keys(local.subnet_to_map) : net => net if contains(var.public_subnets, net) != true }

  # Generate nat-gateway-route-table subnet association map
  private_subnets_list = [for subnet in local.non_public_subnets : subnet]
  # chunk private subnet list by length of public subnets
  split_private_subnets = try(chunklist(
    [for subnet in local.non_public_subnets : subnet],
    ceil(length(local.non_public_subnets) / length(local.public_subnets))
  ), [])
  # create a iterable map of subnets with the corresponding nat-gateway id
  merged_ngw_subnets_map = flatten([
    for key, val in local.split_private_subnets : [
      for v in val : {
        key    = element(values(local.public_subnets), key)
        subnet = v
      }
    ]
  ])
}

# Generate natgateway route-table subnet associations
locals {
  private_subnets_list = [for subnet in local.non_public_subnets : subnet]
  # chunk private subnet list by length of public subnets
  split_private_subnets = try(chunklist(
    [for subnet in local.non_public_subnets : aws_subnet.subnets[subnet].id],
    ceil(length(local.private_subnets_list) / length(local.public_subnets))
  ), [])
  # create a iterable map of subnet and related route-table by split
  merged_chunk_map = flatten([
    for key, val in local.split_private_subnets : [
      for v in val : {
        table  = try(aws_route_table.nat_gateway[element(values(local.public_subnets), key)].id, "")
        subnet = v
      }
    ]
  ])
}

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway == true ? local.public_subnets : {}
  vpc      = true

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      "Name" = format("%s-eip", var.name)
    },
    var.vpc_tags
  )

}

resource "aws_nat_gateway" "ngw" {
  for_each      = var.enable_nat_gateway == true ? local.public_subnets : {}
  allocation_id = aws_eip.nat[each.value].id
  subnet_id     = aws_subnet.subnets[each.value].id
  tags = merge(
    {
      "Name" = format("%s-nat-gateway", var.name)
    },
    var.vpc_tags
  )
}

resource "aws_route_table" "nat_gateway" {
  for_each = var.enable_nat_gateway == true ? local.public_subnets : {}
  vpc_id   = aws_vpc.main.id

  tags = merge(
    {
      "Name" = format("%s-rt-nat-gateway-%s",
        var.name,
      substr(aws_nat_gateway.ngw[each.key].id, 4, 3)) // format id to get 3 random values
    },
    var.vpc_tags
  )
}

resource "aws_route" "nat_gateway" {
  for_each               = var.enable_nat_gateway == true ? local.public_subnets : {}
  route_table_id         = aws_route_table.nat_gateway[each.key].id
  nat_gateway_id         = aws_nat_gateway.ngw[each.value].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "nat_gateway" {
  for_each       = var.enable_nat_gateway == true && length(local.public_subnets) > 0 ? { for values in local.merged_chunk_map : values.subnet => values } : {}
  route_table_id = each.value.table
  subnet_id      = each.value.subnet

  depends_on = [
    aws_route_table.nat_gateway,
    aws_subnet.subnets
  ]
}

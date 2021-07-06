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
  route_table_id         = aws_route_table.nat_gateway[0].id
  nat_gateway_id         = aws_nat_gateway.ngw[each.value].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "nat_gateway" {
  for_each       = var.enable_nat_gateway == true ? local.non_public_subnets : {}
  route_table_id = aws_route_table.nat_gateway[0].id
  subnet_id      = aws_subnet.subnets[each.key].id
}

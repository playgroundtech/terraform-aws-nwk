resource "aws_eip" "ngw" {
  for_each = var.enable_nat_gateway == true ? local.nat_subnets : {}
  vpc      = true

  tags = { "Name" = format("%s-eip-%s", var.name, each.key) }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_nat_gateway" "ngw" {
  for_each      = var.enable_nat_gateway == true ? local.nat_subnets : {}
  allocation_id = aws_eip.ngw[each.key].id
  subnet_id     = aws_subnet.subnets[each.key].id

  tags = { "Name" = format("%s-ngw-%s", var.name, each.key) }
}

resource "aws_route_table" "ngw" {
  for_each = var.enable_nat_gateway == true && var.nat_route_table == true ? local.nat_subnets : {}
  vpc_id   = aws_vpc.main.id
  tags     = { "Name" = format("%s-ngw-rt-%s", var.name, index(keys(local.nat_subnets), each.key)) }
}

resource "aws_route" "ngw" {
  for_each               = var.enable_nat_gateway == true && var.nat_route_table == true ? local.nat_subnets : {}
  route_table_id         = aws_route_table.ngw[each.key].id
  nat_gateway_id         = aws_nat_gateway.ngw[each.key].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "ngw" {
  for_each       = var.enable_nat_gateway == true && var.nat_route_table == true ? { for v in local.merged_chunk_map : v.subnet => v } : {}
  route_table_id = aws_route_table.ngw[each.value.key].id
  subnet_id      = aws_subnet.subnets[each.value.subnet].id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_route_table.ngw
  ]
}

# Add internetgateway and routing on local.public_subnets
resource "aws_internet_gateway" "igw" {
  count  = local.public_subnets != {} || local.bastion_subnets != {} ? 1 : 0
  vpc_id = aws_vpc.main.id
  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.internet_gateway_tags
  )
}

resource "aws_route_table" "igw" {
  count  = local.public_subnets != {} || local.bastion_subnets != {} ? 1 : 0
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.route_table_public_tags
  )
}

resource "aws_route_table_association" "igw" {
  for_each       = local.public_subnets
  route_table_id = aws_route_table.igw[0].id
  subnet_id      = aws_subnet.subnets[each.key].id
}

resource "aws_route_table_association" "igw_bastion" {
  for_each       = local.bastion_subnets
  route_table_id = aws_route_table.igw[0].id
  subnet_id      = aws_subnet.subnets[each.key].id
}

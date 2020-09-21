resource "aws_subnet" "subnets" {
  for_each = local.subnetmap
  cidr_block = each.value["cidr"]
  vpc_id = aws_vpc.main.id
  map_public_ip_on_launch = contains(var.public_subnets,each.key) || contains(var.bastion_subnets,each.key) == true ? true : false
  tags = merge(
  {
    "Name" = format("%s", var.name)
  },
  var.vpc_tags
  )
}

resource "aws_security_group" "security_group" {
  for_each = aws_subnet.subnets
  name = format("%s-security-group", each.key)
  description = "Standard security group for each subnet"
  vpc_id = aws_vpc.main.id
  tags = merge(
  {
    "Name" = format("%s-security-group", each.key)
  },
  var.aws_security_group_tags
  )
}
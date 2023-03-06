resource "aws_subnet" "subnets" {
  for_each                = local.subnet_to_map
  cidr_block              = each.value["cidr"]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = contains(var.public_subnets, each.key) == true ? true : false
  availability_zone       = each.value["az"]
  tags = merge(
    {
      "Name" = "${each.key}-subnet"
    },
    var.vpc_tags
  )
}

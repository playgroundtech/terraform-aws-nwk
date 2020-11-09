resource "aws_subnet" "subnets" {
  for_each                = local.subnetmap
  cidr_block              = each.value["cidr"]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = contains(var.public_subnets, each.key) || contains(var.bastion_subnets, each.key) == true ? true : false
  availability_zone       = each.value["az"]
  tags = merge(
    {
      "Name" = each.key
    },
    var.vpc_tags
  )
}
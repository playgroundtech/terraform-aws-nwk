resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = var.instance_tenancy
  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.vpc_tags
  )
}
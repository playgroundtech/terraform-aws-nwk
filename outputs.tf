output "vpc" {
  value = aws_vpc.main
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnets" {
  value = aws_subnet.subnets
}

output "subnet_ids" {
  value = [for subnets in aws_subnet.subnets : subnets.id]
}

output "subnetmap" {
  value = local.subnetmap
}

output "public_route_table_id" {
  value = try(aws_route_table.igw[0].id, "")
}

output "internet_gateway_id" {
  value = try(aws_internet_gateway.igw[0].id, "")
}

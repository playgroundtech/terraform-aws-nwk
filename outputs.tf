output "vpc" {
  value = aws_vpc.main
}

output "subnets" {
  value = aws_subnet.subnets
}

output "subnetmap" {
  value = local.subnetmap
}

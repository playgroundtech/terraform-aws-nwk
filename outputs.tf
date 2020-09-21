output "vpc" {
  value = aws_vpc.main
}

output "subnets" {
  value = aws_subnet.subnets
}

output "security_groups" {
  value = aws_security_group.security_group
}

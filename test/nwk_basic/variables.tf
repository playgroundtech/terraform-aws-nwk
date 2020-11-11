variable "name" {}
variable "vpc_cidr" {}
variable "subnets_byname" {
  type = list(string)
}
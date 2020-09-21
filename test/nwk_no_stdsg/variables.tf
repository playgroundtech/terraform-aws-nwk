variable "name" {}
variable "vpc_cidr" {}
variable "subnets_byname" {
  type = list(string)
}
variable "subnets_without_stdsg" {
  type = list(string)
}
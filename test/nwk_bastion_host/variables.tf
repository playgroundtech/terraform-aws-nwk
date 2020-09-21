variable "name" {}
variable "vpc_cidr" {}
variable "subnets_byname" {
  type = list(string)
}
variable "bastion_subnets" {}
variable "operating_system" {}
variable "key_pair_name" {}
# Standard Variables
variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

# VPC Variables
variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC."
}

variable "instance_tenancy" {
  type        = string
  description = "A tenancy option for instances launched into the VPC."
  default     = "default"
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}

variable "endpoints" {
  default = []
}

# Subnet Variables
variable "subnet_bits" {
  default = -1
}

variable "subnets_byname" {
  type    = list(string)
  default = []
}

variable "subnets_bybits" {
  type    = list(object({ name = string, bits = number, net = number }))
  default = []
}

variable "subnets_bycidr" {
  type    = list(object({ name = string, cidr = string }))
  default = []
}

variable "subnets_without_stdsg" {
  type    = list(string)
  default = []
}

variable "public_subnets" {
  default = []
  type    = list(string)
}

variable "bastion_subnets" {
  default = []
  type    = list(string)
}

variable "bastion_cidr_blocks" {
  default = ["0.0.0.0/0"]
  type    = list(string)
}

variable "operating_system" {
  description = "The Operating Systems that the machines within the subnets will run on. Opens traffic for SSH or RDP communication within the VPC."
  type        = string
  default     = ""
}

variable "aws_security_group_tags" {
  description = "Additional tags for subnets standard security groups"
  type        = map(string)
  default     = {}
}

# Internet Gateway
variable "internet_gateway_tags" {
  description = "Additional tags for the Internet Gateway"
  type        = map(string)
  default     = {}
}

variable "route_table_public_tags" {
  description = "Additional tags for the Public Route Table"
  type        = map(string)
  default     = {}
}
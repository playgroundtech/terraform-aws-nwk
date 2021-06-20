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

variable "enable_dns_support" {
  description = "A boolean flag to enable/disable DNS support in the VPC."
  type        = bool
  default     = true
}
variable "enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

# Subnet Variables
variable "availability_zone" {
  description = "The AZ for the subnet"
  type        = list(string)
}

variable "subnet_bits" {
  default = -1
}

variable "subnets_byname" {
  description = "The name of the subnets you want to create. Each name will create a new subnet. The subnets will be divided into 8 equally-sized if `subnet_bits` isn't changed"
  type        = list(string)
  default     = []
}

variable "subnets_bybits" {
  description = "List of object to create your subnet. This will create subnet based on bits and net set by the user."
  type        = list(object({ name = string, bits = number, net = number }))
  default     = []
}

variable "subnets_bycidr" {
  description = "List of object to create your subnet. This will create subnets based cidr set by the user."
  type        = list(object({ name = string, cidr = string }))
  default     = []
}

variable "public_subnets" {
  description = "The names of which subnets you want to set as public subnets."
  default     = []
  type        = list(string)
}

# Internet Gateway
variable "internet_gateway" {
  description = "Force creation of Internet Gateway. Only needed when no public or bastion subnets are deployed"
  type        = bool
  default     = false
}

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

# Default ACL
variable "default_network_acl_ingress" {
  description = "List of maps of ingress rules to set on the Default Network ACL"
  type        = list(map(string))

  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no         = 101
      action          = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
}

variable "default_network_acl_egress" {
  description = "List of maps of egress rules to set on the Default Network ACL"
  type        = list(map(string))

  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no         = 101
      action          = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
}

# NAT Gateway

variable "enable_nat_gateway" {
  type        = bool
  default     = true
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
}
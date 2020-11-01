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

variable "bastion_subnets" {
  description = "The name of the subnet which you want to host your bastion host within."
  default     = []
  type        = list(string)
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


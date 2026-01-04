variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "route_table_name" {
  description = "Name of the route table"
  type        = string
}

variable "gateway_id" {
  description = "ID of the Internet Gateway (for public route table)"
  type        = string
  default     = null
}

variable "nat_gateway_id" {
  description = "ID of the NAT Gateway (for private route table)"
  type        = string
  default     = null
}

variable "is_public" {
  description = "Whether this is a public route table"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "ID of the subnet to associate with this route table"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

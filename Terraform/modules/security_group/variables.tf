variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
}

variable "description" {
  description = "Description of the security group"
  type        = string
}

variable "is_public" {
  description = "Whether this is a public security group"
  type        = bool
  default     = false
}

variable "allowed_cidr" {
  description = "CIDR block allowed to access (for public SG)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "source_security_group_id" {
  description = "Source security group ID (for private SG)"
  type        = string
  default     = null
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

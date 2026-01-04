# AWS Region
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

# AWS Credentials
variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

# Environment
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Project Name
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "nt548-lab01"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnet Configuration
variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
  default     = "ap-southeast-1a"
}

# EC2 Configuration
variable "ec2_ami" {
  description = "AMI ID for EC2 instances (Amazon Linux 2)"
  type        = string
  default     = "ami-01811d4912b4ccb26" # Amazon Linux 2 AMI in ap-southeast-1
}

variable "ec2_instance_type" {
  description = "Instance type for EC2"
  type        = string
  default     = "t3.micro"
}

variable "ec2_key_name" {
  description = "Key pair name for EC2 instances"
  type        = string
  default     = "nt548-lab01-key"
}

# Security Configuration
variable "my_ip" {
  description = "Your IP address for SSH access (format: x.x.x.x/32)"
  type        = string
  default     = "0.0.0.0/0" # CHANGE THIS TO YOUR IP FOR SECURITY
}

# Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "NT548-Lab01"
    ManagedBy   = "Terraform"
  }
}

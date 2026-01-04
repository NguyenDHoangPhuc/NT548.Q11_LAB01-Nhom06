output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_default_security_group.default.id
}

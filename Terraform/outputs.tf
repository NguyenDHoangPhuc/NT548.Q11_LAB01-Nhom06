# Outputs - Display important information after deployment

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

# Subnet Outputs
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.public_subnet.subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.private_subnet.subnet_id
}

# Internet Gateway Output
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.internet_gateway.igw_id
}

# NAT Gateway Output
output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.nat_gateway.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = module.nat_gateway.nat_gateway_public_ip
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.public_route_table.route_table_id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = module.private_route_table.route_table_id
}

# Security Group Outputs
output "public_security_group_id" {
  description = "ID of the public security group"
  value       = module.public_security_group.security_group_id
}

output "private_security_group_id" {
  description = "ID of the private security group"
  value       = module.private_security_group.security_group_id
}

# EC2 Outputs
output "public_ec2_id" {
  description = "ID of the public EC2 instance"
  value       = module.public_ec2.instance_id
}

output "public_ec2_public_ip" {
  description = "Public IP of the public EC2 instance"
  value       = module.public_ec2.public_ip
}

output "public_ec2_private_ip" {
  description = "Private IP of the public EC2 instance"
  value       = module.public_ec2.private_ip
}

output "private_ec2_id" {
  description = "ID of the private EC2 instance"
  value       = module.private_ec2.instance_id
}

output "private_ec2_private_ip" {
  description = "Private IP of the private EC2 instance"
  value       = module.private_ec2.private_ip
}

# SSH Connection Instructions
output "ssh_connection_public" {
  description = "SSH command to connect to public EC2 instance"
  value       = "ssh -i ${var.ec2_key_name}.pem ec2-user@${module.public_ec2.public_ip}"
}

output "ssh_connection_private" {
  description = "SSH command to connect to private EC2 instance (via public instance)"
  value       = "First connect to public instance, then: ssh ec2-user@${module.private_ec2.private_ip}"
}

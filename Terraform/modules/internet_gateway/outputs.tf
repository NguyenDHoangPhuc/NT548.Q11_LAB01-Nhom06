output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "igw_arn" {
  description = "ARN of the Internet Gateway"
  value       = aws_internet_gateway.main.arn
}

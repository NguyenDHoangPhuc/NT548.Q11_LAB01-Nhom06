output "route_table_id" {
  description = "ID of the route table"
  value       = aws_route_table.main.id
}

output "route_table_arn" {
  description = "ARN of the route table"
  value       = aws_route_table.main.arn
}

output "route_table_association_id" {
  description = "ID of the route table association"
  value       = aws_route_table_association.main.id
}

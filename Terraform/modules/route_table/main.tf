# Route Table Module - Configure routing for subnets

# Create Route Table
resource "aws_route_table" "main" {
  vpc_id = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = var.route_table_name
      Type = var.is_public ? "Public" : "Private"
    }
  )
}

# Route for Public Route Table (to Internet Gateway)
resource "aws_route" "public" {
  count                  = var.is_public ? 1 : 0
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.gateway_id
}

# Route for Private Route Table (to NAT Gateway)
resource "aws_route" "private" {
  count                  = var.is_public ? 0 : 1
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "main" {
  subnet_id      = var.subnet_id
  route_table_id = aws_route_table.main.id
}

# NAT Gateway Module - Allows private subnet to access Internet securely

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-nat-eip"
    }
  )

  depends_on = [var.subnet_id]
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.subnet_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-nat-gateway"
    }
  )

  # To ensure proper ordering, add an explicit dependency
  depends_on = [aws_eip.nat]
}

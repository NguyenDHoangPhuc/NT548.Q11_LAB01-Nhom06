# Subnet Module - Create Public or Private Subnet

resource "aws_subnet" "main" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = var.is_public

  tags = merge(
    var.common_tags,
    {
      Name = var.subnet_name
      Type = var.is_public ? "Public" : "Private"
    }
  )
}

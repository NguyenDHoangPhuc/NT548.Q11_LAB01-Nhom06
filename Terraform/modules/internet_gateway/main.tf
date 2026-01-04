# Internet Gateway Module - Allows VPC to connect to Internet

resource "aws_internet_gateway" "main" {
  vpc_id = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# Security Group Module - Control inbound and outbound traffic

resource "aws_security_group" "main" {
  name        = var.security_group_name
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = var.security_group_name
      Type = var.is_public ? "Public" : "Private"
    }
  )
}

# Security Group Rules for Public EC2
resource "aws_security_group_rule" "public_ssh" {
  count             = var.is_public ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_cidr]
  description       = "Allow SSH from specific IP"
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "public_http" {
  count             = var.is_public ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from anywhere"
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "public_https" {
  count             = var.is_public ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS from anywhere"
  security_group_id = aws_security_group.main.id
}

# Security Group Rules for Private EC2
resource "aws_security_group_rule" "private_ssh" {
  count                    = var.is_public ? 0 : 1
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.source_security_group_id
  description              = "Allow SSH from public EC2"
  security_group_id        = aws_security_group.main.id
}

resource "aws_security_group_rule" "private_all_from_public" {
  count                    = var.is_public ? 0 : 1
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = var.source_security_group_id
  description              = "Allow all TCP from public EC2"
  security_group_id        = aws_security_group.main.id
}

resource "aws_security_group_rule" "private_icmp" {
  count                    = var.is_public ? 0 : 1
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  source_security_group_id = var.source_security_group_id
  description              = "Allow ICMP from public EC2"
  security_group_id        = aws_security_group.main.id
}

# Egress rule - Allow all outbound traffic
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.main.id
}

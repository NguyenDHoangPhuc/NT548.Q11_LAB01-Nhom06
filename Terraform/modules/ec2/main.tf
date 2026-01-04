# EC2 Module - Create EC2 instances

resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  # Enable detailed monitoring
  monitoring = true

  # Root block device
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = merge(
      var.common_tags,
      {
        Name = "${var.instance_name}-root-volume"
      }
    )
  }

  # User data script
  user_data = var.is_public ? templatefile("${path.module}/user_data_public.sh", {}) : templatefile("${path.module}/user_data_private.sh", {})

  tags = merge(
    var.common_tags,
    {
      Name = var.instance_name
      Type = var.is_public ? "Public" : "Private"
    }
  )

  # Lifecycle
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ami]
  }
}

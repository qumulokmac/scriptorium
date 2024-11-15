################################################################################
#
# File: ./modules/security_group/main.tf main.tf 
#
################################################################################

resource "aws_default_security_group" "default" {
  vpc_id = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    self                     = false
  }

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-default-sg"
  })
}

resource "aws_security_group" "main_sg" {
  vpc_id = var.vpc_id

  description = "Security group for both public and private subnets"
  name        = "${var.common_prefix}-sg"

  ingress {
    description = "Allow SSH from authorized IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [for ip in keys(var.authorized_ips) : var.authorized_ips[ip].ip]
  }

  ingress {
    description = "Allow RDP from authorized IP addresses"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [for ip in keys(var.authorized_ips) : var.authorized_ips[ip].ip]
  }
  ingress {
      from_port = 0
      to_port = 0
      protocol = -1
      self = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-squad"
  })
}

output "sg_id" {
  value = aws_security_group.main_sg.id
}

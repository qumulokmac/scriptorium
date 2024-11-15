###############################################################################
#
# File: ./modules/ec2_instances/main.tf main.tf 
#
################################################################################


###
# CNQ Demo IAM Role
###

resource "aws_iam_role" "ec2_ssm_role" {
  name = "grumpquat-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

###
# CNQ Demo All Inclusive Policy
###

resource "aws_iam_role_policy" "ec2_ssm_role_policy" {
  name   = "grumpquat-ec2-ssm-role-policy"
  role   = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ssm:SendCommand",
          "ssm:DescribeInstanceInformation",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory",
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeTags",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:GetObject",
          "kms:Decrypt"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

###
# Attaching AWS-Managed Policies
###

resource "aws_iam_role_policy_attachment" "ssm_managed_policy_attachment" {
  role       = aws_iam_role.ec2_ssm_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "s3_readonly_policy_attachment" {
  role       = aws_iam_role.ec2_ssm_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

###
# CNQ Demo Instance Profile
###

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "grumpquat-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

################################################################################
# Bastion
################################################################################

resource "aws_eip" "bastion_eip" {
  domain = "vpc"
}

resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}

resource "aws_instance" "bastion" {
  ami           = var.ubuntu_ami_id
  instance_type = "m6in.2xlarge"
  key_name      = var.key_name
  subnet_id     = var.public_subnet_id

  tags = {
   Name = "${var.common_prefix}-bastion"
  }

  associate_public_ip_address = true
  security_groups             = [var.security_group_id]

  user_data = data.aws_s3_object.ubuntu_userdata_script.body

  root_block_device {
    delete_on_termination = false
    volume_size           = 50
    volume_type           = "gp3"
  }

  # instance_market_options {
  #   market_type = "spot"
  #   spot_options {
  #     instance_interruption_behavior = "stop"
  #     spot_instance_type             = "persistent"
  #   }
  # }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  lifecycle {
    prevent_destroy = true
    ignore_changes = [user_data]
  }

  disable_api_termination = true

  depends_on = [var.vpc_id, aws_eip.bastion_eip]
}

################################################################################
# Ubuntu Servers
################################################################################

resource "aws_instance" "ubuntu" {
  count         = var.num_ubuntu_instances
  ami           = var.ubuntu_ami_id
  instance_type = var.instance_types["ubuntu"]
  key_name      = var.key_name
  subnet_id     = var.private_subnet_id

  tags = {
    Name = "${var.common_prefix}-ubuntu-${count.index + 1}"
  }

  associate_public_ip_address = false
  security_groups             = [var.security_group_id]

  user_data = data.aws_s3_object.ubuntu_userdata_script.body

  root_block_device {
    delete_on_termination = false
    volume_size           = 50
    volume_type           = "gp3"
  }

  #    instance_market_options {
  #  market_type = "spot"
  #  spot_options {
  #    instance_interruption_behavior = "stop"
  #    spot_instance_type             = "persistent"
  #  }
  #}

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }

  # placement_group      = "grumpquat-ATRWGUBILG0"
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  depends_on           = [var.vpc_id]
}

################################################################################
# Windows Servers
################################################################################

resource "aws_instance" "windows" {
  count                       = var.num_windows_instances
  ami                         = var.windows_ami_id
  instance_type               = var.instance_types["windows"]
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  security_groups             = [var.security_group_id]
  key_name                    = var.key_name

  user_data                   = base64encode(templatefile("${path.module}/grumpquat-windows-userdata.ps1", {
    AdminPassword = "Qumulo123!!!"
  }))

  root_block_device {
    delete_on_termination = false
    volume_size           = 50
    volume_type           = "gp3"
  }

  #  instance_market_options {
  #  market_type = "spot"
  #
  #  spot_options {
  #    instance_interruption_behavior = "stop"
  #    spot_instance_type             = "persistent"
  #  }
  #}

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 3
    http_tokens                 = "required"
  }

  tags = {
   Name = "${var.common_prefix}-windows-ssm-${count.index + 1}"
  }

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  depends_on = [var.vpc_id]  
}


################################################################################
#
# File: ./modules/ec2_instances/outputs.tf outputs.tf 
#
################################################################################

output "ubuntu_instance_ids" {
  value = aws_instance.ubuntu[*].id
}

output "windows_instance_ids" {
  value = aws_instance.windows[*].id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}

output "ubuntu_private_ips" {
  value = [for instance in aws_instance.ubuntu : instance.private_ip]
}

output "windows_private_ips" {
  value = [for instance in aws_instance.windows : instance.private_ip]
}

################################################################################
#
# File: ./outputs.tf outputs.tf 
#
################################################################################

output "vpc" {
  value = module.vpc.vpc_id
}

output "private_subnet_cidr" {
  value = module.vpc.private_subnet_cidr
}

output "public_subnet_cidr" {
  value = module.vpc.public_subnet_cidr
}

output "harness_security_group"  {
  value = module.security_group.harness_security_group
}

output "ubuntu_worker_ips" {
  description = "Ubuntu Servers Private IP's "
  value       = module.ec2_instances.ubuntu_private_ips
}

output "windows_worker_ips" {
  description = "Windows Servers Private IP's "
  value       = module.ec2_instances.windows_private_ips
}

output "bastion_public_ip"  {
  value = module.ec2_instances.bastion_public_ip
}

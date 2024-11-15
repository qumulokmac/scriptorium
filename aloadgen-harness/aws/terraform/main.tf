################################################################################
#
# File: ./main.tf main.tf 
#
################################################################################

locals {
  common_tags = {
    department  = "marketing",
    owner       = "Kevin McDonald",
    purpose     = "Throughput Benchmark",
    long_running = "false"
  }
}

module "vpc" {
  source = "./modules/vpc"
  common_tags = local.common_tags
  region      = var.region
  cidr_block  = var.cidr_block
  common_prefix = var.common_prefix
}

module "security_group" {
  source = "./modules/security_group"
  vpc_id         = module.vpc.vpc_id
  common_tags    = local.common_tags
  authorized_ips = var.authorized_ips
  common_prefix  = var.common_prefix
}

module "ec2_instances" {
  source = "./modules/ec2_instances"

  region            = var.region
  vpc_id            = module.vpc.vpc_id
  common_tags       = local.common_tags
  ubuntu_ami_id     = data.aws_ami.ubuntu.id
  windows_ami_id    = data.aws_ami.windows.id
  instance_types    = var.instance_types
  key_name          = var.key_name
  public_subnet_id  = module.vpc.public_subnet_id
  private_subnet_id = module.vpc.private_subnet_id
  security_group_id = module.security_group.sg_id
  nat_eip           = module.vpc.nat_eip
  common_prefix     = var.common_prefix
  admin_password    = var.admin_password
  num_windows_instances     = var.num_windows_instances
  num_ubuntu_instances      = var.num_ubuntu_instances

}

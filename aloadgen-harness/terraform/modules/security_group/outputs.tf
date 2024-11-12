################################################################################
#
# File: ./modules/security_group/outputs.tf outputs.tf 
#
################################################################################

output "harness_security_group" {
  value = aws_security_group.main_sg.id
}

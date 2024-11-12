################################################################################
#
# File: ./modules/vpc/outputs.tf outputs.tf 
#
################################################################################

output "private_subnet_cidr" {
  value = aws_subnet.private_subnet.cidr_block
}

output "public_subnet_cidr" {
  value = aws_subnet.public_subnet.cidr_block
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "nat_eip" {
  value = aws_eip.nat.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

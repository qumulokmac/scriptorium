################################################################################
#
# File: ./modules/vpc/main.tf main.tf 
#
################################################################################

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-vpc"
  })
}
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/23"
  availability_zone = "us-east-1c"  
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-public-subnet-subnet"
  })
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/23"
  availability_zone = "us-east-1c"

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-private-subnet-subnet"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-igw"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-nat-gateway"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-nat-eip"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-public-route-table"
  })
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-private-route-table"
  })
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.public.id, aws_route_table.private.id]

  tags = merge(var.common_tags, {
    Name = "${var.common_prefix}-s3-endpoint"
  })
}




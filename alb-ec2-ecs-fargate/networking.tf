
# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.vpc_suffix}-vpc"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = element(local.public_subnets, count.index)
    Tier = "Public"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = element(local.private_subnets, count.index)
    Tier = "Private"
  }
}

#Internet gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_suffix}-igw"
  }
}

# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
  tags = {
    Name = "${var.vpc_suffix}-rtb-public"
  }
}

# Route table associations for both Public subnet
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# NAT Gateway to provide outbound internet access from Private subnet
resource "aws_eip" "nat_gateway" {
  count  = length(var.private_subnets_cidr)
  domain = "vpc"
}

resource "aws_nat_gateway" "nat-gateway" {
  count         = length(var.public_subnets_cidr)
  allocation_id = element(aws_eip.nat_gateway.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)

  tags = {
    Name = "${element(local.public_subnets, count.index)}-natgw"
  }

  # To ensure proper ordering, add Internet Gateway as dependency
  depends_on = [aws_internet_gateway.ig]
}

# Routing tables to route traffic for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  count  = length(var.private_subnets_cidr)
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat-gateway.*.id, count.index)
  }
  tags = {
    Name = "${element(local.private_subnets, count.index)}-rtb"
  }
}

# Route table associations for Private subnet
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

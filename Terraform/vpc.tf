data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_a = data.aws_availability_zones.available.names[0]
  az_b = data.aws_availability_zones.available.names[1]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# ---- Public subnets (AZ-a / AZ-b) - only the NAT Gateway + bastion host live here ----
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = local.az_a
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-1a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = local.az_b
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-2b" }
}

# ---- Private subnets: Web Tier (AZ-a / AZ-b) ----
resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/20"
  availability_zone = local.az_a
  tags              = { Name = "${var.project_name}-private-web-3a" }
}

resource "aws_subnet" "web_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.48.0/20"
  availability_zone = local.az_b
  tags              = { Name = "${var.project_name}-private-web-4b" }
}

# ---- Private subnets: Application Tier (AZ-a / AZ-b) ----
resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.64.0/20"
  availability_zone = local.az_a
  tags              = { Name = "${var.project_name}-private-app-5a" }
}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.80.0/20"
  availability_zone = local.az_b
  tags              = { Name = "${var.project_name}-private-app-6b" }
}

# ---- Private subnets: Database Tier - RDS only lives in AZ-a (single-AZ) ----
resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.160.0/20"
  availability_zone = local.az_a
  tags              = { Name = "${var.project_name}-private-db-7a" }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.176.0/20"
  availability_zone = local.az_b
  tags              = { Name = "${var.project_name}-private-db-8b" }
}

# RDS still needs a subnet *group* spanning 2 AZs even in Single-AZ mode -
# AWS requires this in case you switch to Multi-AZ later.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_b.id]
  tags       = { Name = "${var.project_name}-db-subnet-group" }
}

# ---- NAT Gateway (public subnet A) - lets the private tiers reach the internet ----
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags          = { Name = "${var.project_name}-nat" }
  depends_on    = [aws_internet_gateway.main]
}

# ---- Route tables ----
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-public-rtb" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "${var.project_name}-private-rtb" }
}

resource "aws_route_table_association" "web_a" {
  subnet_id      = aws_subnet.web_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "web_b" {
  subnet_id      = aws_subnet.web_b.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.private.id
}
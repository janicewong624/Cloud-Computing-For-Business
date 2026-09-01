data "aws_region" "current" {}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# ---------------------------------------------------------------------------
# Subnets - matches the diagram exactly: 2 public + 3 private tiers (web/app/
# database) x 2 AZs = 8 subnets total.
# ---------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "web" {
  count                   = length(var.web_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.web_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-private-web-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "app" {
  count                   = length(var.app_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.app_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-private-app-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "db" {
  count                   = length(var.db_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.db_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-private-db-subnet-${count.index + 1}"
  }
}

# ---------------------------------------------------------------------------
# Routing - public subnets get an IGW route (for the external ALB + bastion).
# Private subnets (web/app/db) get NO internet route at all - no NAT Gateway.
# Everything they need reaches them via VPC Endpoints instead (below).
# ---------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private RT has no 0.0.0.0/0 route - kept only so web/app/db subnets share
# one table (and so the S3 Gateway Endpoint below can attach to it).
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-private-rt"
  }
}

resource "aws_route_table_association" "web" {
  count          = length(aws_subnet.web)
  subnet_id      = aws_subnet.web[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db" {
  count          = length(aws_subnet.db)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------------------------
# VPC Endpoints - replace the NAT Gateway entirely for what the private
# tiers actually need.
# ---------------------------------------------------------------------------

# S3 Gateway Endpoint (free, no ENI) - covers BOTH Amazon Linux's S3-backed
# dnf/yum repos AND the App tier's `aws s3 cp`/`head-object` calls against
# the uploads bucket. No NAT needed for either.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id, aws_route_table.private.id]

  tags = {
    Name = "${var.name_prefix}-s3-endpoint"
  }
}

# Secrets Manager Interface Endpoint - the ONE AWS API call the App tier
# makes that S3 doesn't cover (fetching the DB password at boot).
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}-secretsmanager-endpoint"
  }
}
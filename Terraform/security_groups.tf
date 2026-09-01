# assignment-sg-alb: the only SG allowed to receive traffic from the public
# internet. Fronts the external (Web tier) ALB.
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-sg-alb"
  description = "Allow inbound HTTP from the internet to the public ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-sg-alb"
  }
}

# bastion-sg: the only SG allowed to SSH in from the internet, scoped to a
# single known IP. Diagram's bastion host in Public Subnet 1.
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Allow SSH from the operator IP only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from the operator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-bastion-sg"
  }
}

# web-sg: Web tier EC2 instances. HTTP only from the public ALB; SSH only
# from the bastion host.
resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web-sg"
  description = "Web tier: HTTP from the public ALB only, SSH from the bastion only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from the public ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "SSH from the bastion host only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-web-sg"
  }
}

# app-sg: App tier EC2 instances (and the internal ALB in front of them).
# HTTP only from the Web tier; SSH only from the bastion.
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "App tier: HTTP from the Web tier only, SSH from the bastion only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from the Web tier only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    description     = "SSH from the bastion host only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-app-sg"
  }
}

# database-sg: RDS. MySQL only from the App tier.
resource "aws_security_group" "database" {
  name        = "${var.name_prefix}-database-sg"
  description = "Database tier: MySQL from the App tier only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "MySQL from the App tier only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-database-sg"
  }
}

# vpc-endpoints-sg: allows the App tier to reach the Secrets Manager
# Interface Endpoint's ENI over HTTPS. Nothing else needs to talk to it.
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Allow HTTPS from the App tier to the Secrets Manager interface endpoint"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTPS from the App tier only"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-vpc-endpoints-sg"
  }
}
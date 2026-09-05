# alb-sg: the only security group allowed to receive traffic from the public
# internet, matching the architecture diagram.
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Allow inbound HTTP from the internet to the ALB"
  vpc_id      = var.vpc_id

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
    Name = "${var.name_prefix}-alb-sg"
  }
}

# bastion-sg: SSH only from your own IP, never Anywhere-IPv4. The bastion
# sits in the public subnet purely as a documented manual-access path into
# the private tiers (matches the architecture diagram) - normal app
# deployment never uses it, since instances self-deploy from S3 on boot.
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Allow SSH only from your own IP"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
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

# app-sg: app instances only ever accept HTTP from the ALB, and SSH only
# from the bastion host - never a raw CIDR block, matching the diagram's
# bastion -> app tier arrow.
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Allow HTTP only from the ALB, SSH only from the bastion"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
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
    Name = "${var.name_prefix}-app-sg"
  }
}

# database-sg: only the app instances may reach the database.
resource "aws_security_group" "database" {
  name        = "${var.name_prefix}-database-sg"
  description = "Allow MySQL/Aurora only from application instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL/Aurora from app instances only"
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

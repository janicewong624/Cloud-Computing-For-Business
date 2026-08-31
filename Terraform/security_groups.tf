# ---- External ALB: only thing allowed to accept traffic from the internet ----
resource "aws_security_group" "external_alb" {
  name        = "${var.project_name}-external-alb-sg"
  description = "Allow HTTP from the internet only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
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

  tags = { Name = "${var.project_name}-external-alb-sg" }
}

# ---- Web tier EC2: only reachable from the external ALB ----
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP only from the external ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from external ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.external_alb.id]
  }

  ingress {
    description     = "SSH from bastion host only"
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

  tags = { Name = "${var.project_name}-web-sg" }
}

# ---- Internal ALB: sits between web tier and app tier, only reachable from web tier ----
resource "aws_security_group" "internal_alb" {
  name        = "${var.project_name}-internal-alb-sg"
  description = "Allow HTTP only from the web tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from web tier"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-internal-alb-sg" }
}

# ---- App tier EC2: only reachable from the internal ALB ----
resource "aws_security_group" "app" {
  name        = "${var.project_name}-appserver-sg"
  description = "Allow HTTP only from the internal ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from internal ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }

  ingress {
    description     = "SSH from bastion host only"
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

  tags = { Name = "${var.project_name}-appserver-sg" }
}

# ---- Database: only reachable on 3306 from the web tier and app tier ----
resource "aws_security_group" "database" {
  name        = "${var.project_name}-database-sg"
  description = "Allow MySQL only from the web/app tiers - no public access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from web tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    description     = "MySQL from app tier"
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

  tags = { Name = "${var.project_name}-database-sg" }
}

# ---- Bastion host: SSH from your own IP only (fill this in!) ----
variable "my_ip_cidr" {
  description = "Your own public IP in CIDR form (e.g. 1.2.3.4/32) - find it at whatismyip.com. Never leave this as 0.0.0.0/0."
  type        = string
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Allow SSH only from your own IP"
  vpc_id      = aws_vpc.main.id

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

  tags = { Name = "${var.project_name}-bastion-sg" }
}
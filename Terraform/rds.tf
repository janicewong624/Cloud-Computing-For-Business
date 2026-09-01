# assignment-rds: single-AZ sandbox MySQL instance. The DB subnet group still
# needs subnets in >= 2 AZs (an AWS hard requirement) even though the
# instance itself is single-AZ - matches the diagram's empty 2nd DB subnet.
resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-rds"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]

  multi_az            = false
  publicly_accessible = false

  # Sandbox environment: prioritize cheap/disposable over durability.
  skip_final_snapshot     = true
  backup_retention_period = 1
  deletion_protection     = false
  apply_immediately       = true

  tags = {
    Name = "${var.name_prefix}-rds"
  }
}

# assignment-db-credentials: single source of truth for the app's DB
# connection info. App tier instances read this at boot via their IAM role -
# no credentials ever hardcoded in an AMI or user-data.
resource "aws_secretsmanager_secret" "db" {
  name                    = var.secret_name
  description             = "RDS connection details for the library-resource-scheduling app (${var.name_prefix} sandbox)"
  recovery_window_in_days = 0 # skip 30-day soft-delete; allows immediate re-creation

  tags = {
    Name = var.secret_name
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
    username = var.db_username
    password = random_password.db.result
  })
}
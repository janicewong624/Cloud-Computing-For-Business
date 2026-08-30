resource "aws_db_instance" "main" {
  identifier     = "library-db"
  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  multi_az               = false # Single-AZ, matches the diagram (Private Subnet 8 stays empty)
  publicly_accessible    = false
  skip_final_snapshot    = true  # OK for a class POC - don't do this in real production
  backup_retention_period = 0    # No automated backups needed for a short-lived lab demo
  deletion_protection    = false # So `terraform destroy` can actually tear it down

  tags = { Name = "library-db" }
}
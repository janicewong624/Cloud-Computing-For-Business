resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Plain RDS MySQL. If you'd rather use Aurora MySQL instead, set
# var.db_engine = "aurora-mysql" and swap this resource for an
# aws_rds_cluster + aws_rds_cluster_instance pair (left as a single
# instance here to match the AWS Academy Learner Lab's usual quota limits).
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = var.db_engine
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type       = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Requirement: RDS must NOT be publicly accessible and must run on a
  # private subnet - both enforced here.
  publicly_accessible = false
  multi_az             = false

  skip_final_snapshot       = true
  backup_retention_period   = 1
  deletion_protection       = false
  apply_immediately         = true

  tags = {
    Name = "${var.project_name}-db"
  }
}

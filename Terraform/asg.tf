data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

variable "app_subdir" {
  description = "Subfolder inside your git repo containing the PHP app (e.g. 'library-resource-scheduling' if your repo has multiple project folders)"
  type        = string
  default     = "library-resource-scheduling"
}

# ---- Web Tier ----
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.web_instance_type
  key_name      = var.key_pair_name

  iam_instance_profile {
    name = var.lab_instance_profile_name
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    git_repo_url = var.git_repo_url
    app_subdir   = var.app_subdir
    db_host      = aws_db_instance.main.address
    db_username  = var.db_username
    db_password  = var.db_password
    db_name      = var.db_name
    s3_bucket    = aws_s3_bucket.photos.bucket
    aws_region   = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"
    tags           = { Name = "${var.project_name}-web" }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  vpc_zone_identifier = [aws_subnet.web_a.id, aws_subnet.web_b.id]
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  min_size         = var.asg_min_size
  desired_capacity = var.asg_desired_capacity
  max_size         = var.asg_max_size

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_cpu" {
  name                   = "${var.project_name}-web-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

# ---- Application Tier ----
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.app_instance_type
  key_name      = var.key_pair_name

  iam_instance_profile {
    name = var.lab_instance_profile_name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    git_repo_url = var.git_repo_url
    app_subdir   = var.app_subdir
    db_host      = aws_db_instance.main.address
    db_username  = var.db_username
    db_password  = var.db_password
    db_name      = var.db_name
    s3_bucket    = aws_s3_bucket.photos.bucket
    aws_region   = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"
    tags           = { Name = "${var.project_name}-app" }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-app-asg"
  vpc_zone_identifier = [aws_subnet.app_a.id, aws_subnet.app_b.id]
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"

  min_size         = var.asg_min_size
  desired_capacity = var.asg_desired_capacity
  max_size         = var.asg_max_size

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "app_cpu" {
  name                   = "${var.project_name}-app-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

# ---- Bastion host (public subnet A) ----
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.public_a.id
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = { Name = "${var.project_name}-bastion" }
}
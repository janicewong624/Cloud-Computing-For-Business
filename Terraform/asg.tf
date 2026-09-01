data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Referenced, never created - Academy Learner Lab accounts block new IAM
# roles/instance profiles, so instances reuse the pre-provisioned LabRole.
data "aws_iam_instance_profile" "lab" {
  name = var.instance_profile_name
}

# ---------------------------------------------------------------------------
# Web tier - pure reverse proxy, never talks to RDS.
# ---------------------------------------------------------------------------
resource "aws_launch_template" "web" {
  name_prefix   = "${var.name_prefix}-web-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    tier             = "web"
    app_alb_dns_name = aws_lb.app.dns_name
    secret_arn       = aws_secretsmanager_secret.db.arn
    aws_region       = var.aws_region
    artifact_bucket  = aws_s3_bucket.uploads.id
    artifact_key     = var.artifact_key
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-web-ec2"
      App  = "${var.name_prefix}-library-web"
    }
  }

  tags = {
    Name = "${var.name_prefix}-web-lt"
  }
}

resource "aws_autoscaling_group" "web" {
  name = "${var.name_prefix}-web-asg"

  vpc_zone_identifier        = aws_subnet.web[*].id
  min_size                   = var.web_asg_min_size
  max_size                   = var.web_asg_max_size
  desired_capacity           = var.web_asg_desired_capacity
  health_check_type          = "ELB"
  health_check_grace_period  = 300
  target_group_arns          = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-web-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "App"
    value               = "${var.name_prefix}-library-web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_cpu_target_tracking" {
  name                   = "${var.name_prefix}-web-asg-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60
  }
}

# ---------------------------------------------------------------------------
# App tier - runs the actual PHP app, talks to RDS.
# ---------------------------------------------------------------------------
resource "aws_launch_template" "app" {
  name_prefix   = "${var.name_prefix}-app-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    tier             = "app"
    app_alb_dns_name = aws_lb.app.dns_name
    secret_arn       = aws_secretsmanager_secret.db.arn
    aws_region       = var.aws_region
    artifact_bucket  = aws_s3_bucket.uploads.id
    artifact_key     = var.artifact_key
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-app-ec2"
      App  = "${var.name_prefix}-library-app"
    }
  }

  tags = {
    Name = "${var.name_prefix}-app-lt"
  }
}

resource "aws_autoscaling_group" "app" {
  name = "${var.name_prefix}-app-asg"

  vpc_zone_identifier        = aws_subnet.app[*].id
  min_size                   = var.app_asg_min_size
  max_size                   = var.app_asg_max_size
  desired_capacity           = var.app_asg_desired_capacity
  health_check_type          = "ELB"
  health_check_grace_period  = 300
  target_group_arns          = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-app-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "App"
    value               = "${var.name_prefix}-library-app"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "app_cpu_target_tracking" {
  name                   = "${var.name_prefix}-app-asg-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60
  }
}

# ---------------------------------------------------------------------------
# Bastion host - single EC2 in Public Subnet 1, SSH jump box into the
# Web/App tiers. Not part of the app's traffic path.
# ---------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  iam_instance_profile        = data.aws_iam_instance_profile.lab.name

  tags = {
    Name = "${var.name_prefix}-bastion"
  }
}
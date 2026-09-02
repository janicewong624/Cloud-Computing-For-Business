# Fallback AMI (plain Amazon Linux 2023) used only until you've baked your
# own golden AMI with the app pre-installed (see README.md "Building the
# golden AMI"). Once you set var.ami_id, that overrides this.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.instance_profile_name
  }

  # Requirement: ASG instances must NOT have a public IP. (Security groups
  # go inside network_interfaces, not vpc_security_group_ids, once you're
  # setting associate_public_ip_address here - Terraform rejects both being
  # set at once.)
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2.id]
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    db_host   = aws_db_instance.main.address
    db_name   = var.db_name
    db_user   = var.db_username
    db_pass   = var.db_password
    s3_bucket = aws_s3_bucket.uploads.bucket
    s3_region = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 300

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

resource "aws_autoscaling_policy" "target_tracking_cpu" {
  name                   = "${var.project_name}-target-tracking-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = var.asg_target_cpu
    disable_scale_in = false
  }

  # Matches the 300s instance warmup from the console flow: gives a freshly
  # launched instance time to boot/register healthy before its CPU metric
  # counts toward the next scaling decision.
  estimated_instance_warmup = 300
}

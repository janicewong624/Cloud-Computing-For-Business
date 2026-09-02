data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "aws_iam_instance_profile" "lab_profile" {
  name = "LabRole"
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-launch-template-"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  
  key_name      = "Library2"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  iam_instance_profile {
    arn = data.aws_iam_instance_profile.lab_profile.arn
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {}))
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id]
  target_group_arns   = [aws_lb_target_group.alb_tg.arn]
  health_check_type   = "ELB"

  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}
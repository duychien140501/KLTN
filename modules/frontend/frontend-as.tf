# Launch Template for Frontend Instances
resource "aws_launch_template" "frontend" {
  name_prefix   = "frontend-template-"
  image_id      = "ami-0fc5d935ebf8bc3bc" 
  instance_type = "t2.micro"
  key_name      = var.ssh-key-name
  vpc_security_group_ids = [aws_security_group.frontend-sg.id]
}

# Auto Scaling Group for Frontend Instances
resource "aws_autoscaling_group" "frontend" {
  desired_capacity     = 0
  max_size             = 2
  min_size             = 0
  vpc_zone_identifier  = var.frontend-subnet-ids 
  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "FE created by Auto Scale"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy for Scaling Up
resource "aws_autoscaling_policy" "frontend_scale_up" {
  name                   = "frontend-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}

# Auto Scaling Policy for Scaling Down
resource "aws_autoscaling_policy" "frontend_scale_down" {
  name                   = "frontend-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}

# CloudWatch Metric Alarm for Scaling Up
resource "aws_cloudwatch_metric_alarm" "frontend_high_request_count" {
  alarm_name                = "high-request-count"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "RequestCountPerTarget"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1000"
  alarm_description         = "This metric monitors high request count for frontend"
  dimensions = {
    "LoadBalancer" = aws_lb.fe-alb.arn_suffix
    "TargetGroup"  = aws_lb_target_group.frontend-tg.arn_suffix
  }
  alarm_actions             = [aws_autoscaling_policy.frontend_scale_up.arn]
}

# CloudWatch Metric Alarm for Scaling Down
resource "aws_cloudwatch_metric_alarm" "frontend_low_request_count" {
  alarm_name                = "low-request-count"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "RequestCountPerTarget"
  namespace                 = "AWS/ApplicationELB"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "500"
  alarm_description         = "This metric monitors low request count for frontend"
  dimensions = {
    "LoadBalancer" = aws_lb.fe-alb.arn_suffix
    "TargetGroup"  = aws_lb_target_group.frontend-tg.arn_suffix
  }
  alarm_actions             = [aws_autoscaling_policy.frontend_scale_down.arn]
}
# Launch Template for Backend Instances
resource "aws_launch_template" "backend" {
  name_prefix            = "backend-template-"
  image_id               = var.ubuntu-ami
  instance_type          = var.instance_type
  key_name               = var.ssh-key-name
  vpc_security_group_ids = [aws_security_group.backend-sg.id]

}

# Auto Scaling Group for Backend Instances
resource "aws_autoscaling_group" "backend" {
  desired_capacity    = 0
  max_size            = 2
  min_size            = 0
  vpc_zone_identifier = var.backend-subnet-ids
  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "BE created by Auto Scale"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy for Scaling Up
resource "aws_autoscaling_policy" "backend_scale_up" {
  name                   = "backend-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend.name
}

# Auto Scaling Policy for Scaling Down
resource "aws_autoscaling_policy" "backend_scale_down" {
  name                   = "backend-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend.name
}

# CloudWatch Metric Alarm for Scaling Up
resource "aws_cloudwatch_metric_alarm" "backend_high_cpu" {
  alarm_name          = "high-cpu-backend"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "This metric monitors high CPU utilization for backend"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.backend.name
  }
  alarm_actions = [aws_autoscaling_policy.backend_scale_up.arn]
}

# CloudWatch Metric Alarm for Scaling Down
resource "aws_cloudwatch_metric_alarm" "backend_low_cpu" {
  alarm_name          = "low-cpu-backend"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors low CPU utilization for backend"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.backend.name
  }
  alarm_actions = [aws_autoscaling_policy.backend_scale_down.arn]
}

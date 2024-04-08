# Backend Load balancer Security group
resource "aws_security_group" "be-alb-sg" {
  name        = "ALB_Backend_SG"
  description = "Security Group for Backend load balancer created via Terraform"
  vpc_id      = var.vpc-id

  ingress = [
    {
      description      = "Allow all traffic"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = [var.internet-cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = "Allow to BE"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = var.backend-subnet-cidrs
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "ALB_Backend_SG"
  }
}

# Load balancer
resource "aws_lb" "be-alb" {
  name                             = "backend-alb"
  internal                         = false
  load_balancer_type               = "application"                     # application
  security_groups                  = [aws_security_group.be-alb-sg.id] # choose security groups
  subnets                          = var.public-subnet-ids             # choose public subnet
  enable_cross_zone_load_balancing = true                              # cross zone
  enable_deletion_protection       = false

  tags = {
    Environment = "backend app"
  }

  depends_on = [aws_security_group.be-alb-sg]
}

# Backend SG
resource "aws_security_group" "backend-sg" {
  name        = "Backend-SG"
  description = "Security Group for Backend created by terraform"
  vpc_id      = var.vpc-id

  ingress = [
    {
      description      = "Allow to be-alb"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.be-alb-sg.id]
      self             = false
    },
    {
      description      = "Allow Bastion SSH"
      from_port        = 2222
      to_port          = 2222
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [var.bastion-sg-id]
      self             = false
    }
  ]

  egress = [
    {
      description      = "allow Nat port 80"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [var.nat-sg-id]
      self             = false
    },
    {
      description      = "allow Nat port 443"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [var.nat-sg-id]
      self             = false
    },
    {
      description      = "allow DB"
      from_port        = 3306
      to_port          = 3306
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [var.database-sg-id]
      self             = false
    }

  ]

  tags = {
    Name = "Backend Security Group"

  }

}

# log group
resource "aws_cloudwatch_log_group" "be-log-group" {
  name = "backend.log"
}

# Backend instance
resource "aws_instance" "backend" {
  count                  = length(var.backend-subnet-ids)
  ami                    = var.ubuntu-ami
  instance_type          = "t2.micro"
  key_name               = var.ssh-key-name
  subnet_id              = var.backend-subnet-ids[count.index]
  vpc_security_group_ids = [aws_security_group.backend-sg.id]
  iam_instance_profile   = var.cloudwatch_instance_profile_name
  user_data              = file("${path.module}/beinstance.sh")

  tags = {
    Name = "Backend ${count.index + 1} creating by terraform"
  }

  depends_on = [aws_security_group.backend-sg]
}

# create target group
resource "aws_lb_target_group" "backend-tg" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc-id
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

}

# create target attachment
resource "aws_lb_target_group_attachment" "attach-backend" {
  count            = length(aws_instance.backend)
  target_group_arn = aws_lb_target_group.backend-tg.arn
  target_id        = aws_instance.backend[count.index].id
  port             = 8080

  depends_on = [aws_instance.backend, aws_lb_target_group.backend-tg]
}

# create listener
resource "aws_lb_listener" "be_listener" {
  load_balancer_arn = aws_lb.be-alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend-tg.arn
  }

  depends_on = [aws_lb.be-alb, aws_lb_target_group.backend-tg]
}

# Launch Template for Backend Instances
resource "aws_launch_template" "backend" {
  name_prefix   = "backend-template-"
  image_id      = "ami-0fc5d935ebf8bc3bc"  
  instance_type = "t2.micro"     
  key_name      = var.ssh-key-name
  vpc_security_group_ids = [aws_security_group.backend-sg.id]
}

# Auto Scaling Group for Backend Instances
resource "aws_autoscaling_group" "backend" {
  desired_capacity     = 0
  max_size             = 2  
  min_size             = 0  
  vpc_zone_identifier  = var.backend-subnet-ids
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
  alarm_name                = "high-cpu-backend"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors high CPU utilization for backend"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.backend.name
  }
  alarm_actions             = [aws_autoscaling_policy.backend_scale_up.arn]
}

# CloudWatch Metric Alarm for Scaling Down
resource "aws_cloudwatch_metric_alarm" "backend_low_cpu" {
  alarm_name                = "low-cpu-backend"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "This metric monitors low CPU utilization for backend"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.backend.name
  }
  alarm_actions             = [aws_autoscaling_policy.backend_scale_down.arn]
}
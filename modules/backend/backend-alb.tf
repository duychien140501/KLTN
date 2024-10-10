# Backend Load balancer Security group
resource "aws_security_group" "be_alb_sg" {
  name        = "ALB_Backend_SG"
  description = "Security Group for Backend load balancer created via Terraform"
  vpc_id      = var.vpc_id

  ingress = [
    {
      description      = "Allow all traffic"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = [var.internet_cidr]
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
      cidr_blocks      = var.backend_subnet_cidrs
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
resource "aws_lb" "be_alb" {
  name                             = "backend-alb"
  internal                         = false
  load_balancer_type               = "application"                     # application
  security_groups                  = [aws_security_group.be_alb_sg.id] # choose security groups
  subnets                          = var.public_subnet_ids             # choose public subnet
  enable_cross_zone_load_balancing = true                              # cross zone
  enable_deletion_protection       = false

  tags = {
    Environment = "backend app"
  }

  depends_on = [aws_security_group.be_alb_sg]
}

# create target group
resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 16
    unhealthy_threshold = 2
  }

}

# create target attachment
resource "aws_lb_target_group_attachment" "attach_backend" {
  count            = length(aws_instance.backend)
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend[count.index].id
  port             = 8080

  depends_on = [aws_instance.backend, aws_lb_target_group.backend_tg]
}

# create listener
resource "aws_lb_listener" "be_listener" {
  load_balancer_arn = aws_lb.be_alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  depends_on = [aws_lb.be_alb, aws_lb_target_group.backend_tg]
}

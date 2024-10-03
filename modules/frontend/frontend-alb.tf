# Frontend Load balancer Security group
resource "aws_security_group" "fe-alb-sg" {
  name        = "ALB_frontend_SG"
  description = "Security Group for Frontend load balancer created via Terraform"
  vpc_id      = var.vpc-id

  ingress = [
    {
      description      = "Allow all traffic port 80"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = [var.internet-cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow all traffic port 82"
      from_port        = 82
      to_port          = 82
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
      description      = "Allow to FE port 80"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = var.frontend-subnet-cidrs
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow to Admin port 82"
      from_port        = 82
      to_port          = 82
      protocol         = "tcp"
      cidr_blocks      = var.frontend-subnet-cidrs
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "ALB_Frontend_SG"
  }
}

# Frontend Load balancer resource
resource "aws_lb" "fe-alb" {
  name                             = "frontend-alb"
  internal                         = false
  load_balancer_type               = "application"                     # application
  security_groups                  = [aws_security_group.fe-alb-sg.id] # choose security groups
  subnets                          = var.public-subnet-ids             # choose public subnet
  enable_cross_zone_load_balancing = true                              # cross zone
  enable_deletion_protection       = false

  tags = {
    Environment = "frontend app"
  }

  depends_on = [aws_security_group.fe-alb-sg]
}

# create target group
resource "aws_lb_target_group" "frontend-tg" {
  name     = "frontend-tg"
  port     = 80
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
    timeout             = 9
    unhealthy_threshold = 3
  }

}

# create target attachment
resource "aws_lb_target_group_attachment" "attach-frontend" {
  count            = length(aws_instance.frontend)
  target_group_arn = aws_lb_target_group.frontend-tg.arn
  target_id        = aws_instance.frontend[count.index].id
  port             = 80
}

# create listener
resource "aws_lb_listener" "fe_listener" {
  load_balancer_arn = aws_lb.fe-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend-tg.arn
  }

  depends_on = [aws_lb.fe-alb, aws_lb_target_group.frontend-tg]
}

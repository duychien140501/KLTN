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

# Frontend SG
resource "aws_security_group" "admin-sg" {
  name        = "AdminSG"
  description = "Security Group for Admin created by terraform"
  vpc_id      = var.vpc-id

  ingress = [
    {
      description      = "allow Bastion SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [var.bastion-sg-id]
      self             = false
    },
    {
      description      = "Allow to fe-alb"
      from_port        = 82
      to_port          = 82
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.fe-alb-sg.id]
      self             = false
    }
  ]

  egress = [
    {
      description      = "allow Nat port 80"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "allow Nat port 443"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "Frontend Security Group"

  }

}

# log group
resource "aws_cloudwatch_log_group" "adm-log-group" {
  name = "adm-access.log"
}

resource "aws_cloudwatch_log_group" "adm-error-group" {
  name = "adm-error.log"
}

# admin instance
resource "aws_instance" "admin" {
  count                  = length(var.frontend-subnet-ids)
  ami                    = var.ubuntu-ami
  instance_type          = var.instance_type
  key_name               = var.ssh-key-name
  subnet_id              = var.frontend-subnet-ids[count.index]
  vpc_security_group_ids = [aws_security_group.admin-sg.id]
  iam_instance_profile   = var.cloudwatch_instance_profile_name
  user_data              = file("${path.module}/admin.sh")
  tags = {
    Name = "Admin ${count.index + 1} creating by terraform"
  }

  depends_on = [aws_security_group.admin-sg]
}

# create target group
resource "aws_lb_target_group" "admin-tg" {
  name     = "admin-tg"
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
    timeout             = 5
    unhealthy_threshold = 2
  }

}

# create target attachment
resource "aws_lb_target_group_attachment" "attach-admin" {
  count            = length(aws_instance.admin)
  target_group_arn = aws_lb_target_group.admin-tg.arn
  target_id        = aws_instance.admin[count.index].id
  port             = 82
}

# create listener
resource "aws_lb_listener" "admin_listener" {
  load_balancer_arn = aws_lb.fe-alb.arn
  port              = "82"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin-tg.arn
  }

  depends_on = [aws_lb.fe-alb, aws_lb_target_group.admin-tg]
}

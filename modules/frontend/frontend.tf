# Frontend SG
resource "aws_security_group" "frontend-sg" {
  name        = "Frontend-SG"
  description = "Security Group for Frontend created by terraform"
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
      description      = "Allow from fe-alb"
      from_port        = 80
      to_port          = 80
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

  depends_on = [aws_security_group.fe-alb-sg]

}

# log group
resource "aws_cloudwatch_log_group" "fe-log-group" {
  name = "fe-access.log"
}

resource "aws_cloudwatch_log_group" "fe-error-group" {
  name = "fe-error.log"
}

# frontend instance
resource "aws_instance" "frontend" {
  count                  = length(var.frontend-subnet-ids)
  ami                    = var.ubuntu-ami
  instance_type          = var.instance_type
  key_name               = var.ssh-key-name
  subnet_id              = var.frontend-subnet-ids[count.index]
  vpc_security_group_ids = [aws_security_group.frontend-sg.id]
  iam_instance_profile   = var.cloudwatch_instance_profile_name
  user_data              = file("${path.module}/frontend.sh")
          
  tags = {
    Name = "Frontend ${count.index + 1} creating by terraform"
  }

  depends_on = [aws_security_group.frontend-sg]
}

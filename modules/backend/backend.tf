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
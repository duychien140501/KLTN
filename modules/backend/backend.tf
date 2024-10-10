# Backend SG
resource "aws_security_group" "backend_sg" {
  name        = "Backend_SG"
  description = "Security Group for Backend created by terraform"
  vpc_id      = var.vpc_id

  ingress = [
    {
      description      = "Allow to be_alb"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.be_alb_sg.id]
      self             = false
    },
    {
      description      = "Allow Bastion SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [var.bastion_sg_id]
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
    },
    {
      description      = "allow DB"
      from_port        = 3306
      to_port          = 3306
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [var.database_sg_id]
      self             = false
    }

  ]

  tags = {
    Name = "Backend Security Group"

  }

}

# log group
resource "aws_cloudwatch_log_group" "be_log_group" {
  name = "backend.log"
}

# Backend instance
resource "aws_instance" "backend" {
  count                  = length(var.backend_subnet_ids)
  ami                    = var.ubuntu_ami
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = var.backend_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  iam_instance_profile   = var.cloudwatch_instance_profile_name
  user_data              = file("${path.module}/beinstance.sh")

  tags = {
    Name = "Backend ${count.index + 1} creating by terraform"
  }

  depends_on = [aws_security_group.backend_sg]
}

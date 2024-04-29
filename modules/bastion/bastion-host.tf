# Bastion SG
resource "aws_security_group" "bastion-sg" {
  name        = "Bastion-Host-SG"
  description = "Security Group for Bastion host created by terraform"
  vpc_id      = var.vpc-id

  ingress = [
    {
      description      = "allow SSH from local"
      from_port        = 22
      to_port          = 22
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
      description      = "SSH to DB, BE, FE, Admin"
      from_port        = 2222
      to_port          = 2222
      protocol         = "tcp"
      cidr_blocks      = [var.vpc-cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "Bastion host Security Group"

  }
}

resource "aws_instance" "bastion-host" {
  ami                         = var.ubuntu-ami
  instance_type               = "t2.micro"
  key_name                    = var.ssh-key-name
  subnet_id                   = var.public-subnet-ids[0]           # first public subnet
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id] # vpc_security_group_ids cho pb > 0.12
  associate_public_ip_address = true

  user_data = file("${path.module}/bastioninstance.sh")

  tags = {
    Name = "Bastion host creating by terraform"
  }

  depends_on = [aws_security_group.bastion-sg]
}

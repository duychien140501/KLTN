# Bastion SG
resource "aws_security_group" "bastion_sg" {
  name        = "Bastion_Host_SG"
  description = "Security Group for Bastion host created by terraform"
  vpc_id      = var.vpc_id

  ingress = [
    {
      description      = "allow SSH from local"
      from_port        = 22
      to_port          = 22
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
      description      = "SSH to DB, BE, FE, Admin"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = [var.vpc_cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "network"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
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

resource "aws_instance" "bastion_host" {
  ami                         = var.ubuntu_ami
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  subnet_id                   = var.public_subnet_ids[0]           # first public subnet
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id] # vpc_security_group_ids cho pb > 0.12
  associate_public_ip_address = true

  user_data = file("${path.module}/bastioninstance.sh")

  tags = {
    Name = "Bastion host creating by terraform"
  }

  depends_on = [aws_security_group.bastion_sg]
}

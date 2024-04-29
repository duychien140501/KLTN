# Bastion SG
resource "aws_security_group" "database-sg" {
  name        = "Database-SG"
  description = "Security Group for Database created by terraform"
  vpc_id      = var.vpc-id

  ingress = [
    {
      description      = "allow BE connect"
      from_port        = 3306
      to_port          = 3306
      protocol         = "tcp"
      cidr_blocks      = var.backend-subnet-cidrs
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "allow Bastion SSH"
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
    }
  ]

  tags = {
    Name = "Database Security Group"

  }
}

resource "aws_network_interface" "database-ni" {
  subnet_id       = var.database-subnet-ids[0]
  private_ips     = [var.private-ip]
  security_groups = [aws_security_group.database-sg.id]
  tags = {
    Name        = "db-ni"
    Description = "network interface for database instance"
  }
}

resource "aws_instance" "database-instance" {
  ami           = var.ubuntu-ami
  instance_type = "t2.micro"
  key_name      = var.ssh-key-name
  user_data     = file("${path.module}/dbinstance.sh")

  network_interface {
    network_interface_id = aws_network_interface.database-ni.id
    device_index         = 0
  }

  tags = {
    Name = "Database instance creating by terraform"
  }

  depends_on = [aws_security_group.database-sg, aws_network_interface.database-ni]
}

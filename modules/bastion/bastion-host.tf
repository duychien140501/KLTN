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

  user_data = <<-EOF
    #!/bin/bash
    echo "change default username"
    user=${var.default-name}
    usermod  -l $user ubuntu
    groupmod -n $user ubuntu
    usermod  -d /home/$user -m $user
    if [ -f /etc/sudoers.d/90-cloudimg-ubuntu ]; then
    mv /etc/sudoers.d/90-cloudimg-ubuntu /etc/sudoers.d/90-cloud-init-users
    fi
    perl -pi -e "s/ubuntu/$user/g;" /etc/sudoers.d/90-cloud-init-users
  EOF

  tags = {
    Name = "Bastion host creating by terraform"
  }

  depends_on = [aws_security_group.bastion-sg]
}

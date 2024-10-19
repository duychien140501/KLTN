data "aws_availability_zones" "available" {}

# Create a security group for Elasticsearch
resource "aws_security_group" "logging_sg" {
  name        = "logging_sg"
  description = "Security group for logging"
  vpc_id      = var.vpc_id

  ingress = [
    {
      description      = "Allow to https"
      from_port        = 5601
      to_port          = 5601
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow to logstash"
      from_port        = 5044
      to_port          = 5044
      protocol         = "tcp"
      cidr_blocks      = [var.vpc_cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow to elasticsearch"
      from_port        = 9200
      to_port          = 9200
      protocol         = "tcp"
      cidr_blocks      = [var.vpc_cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
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
    }
    , {
      description      = "Allow to kibana"
      from_port        = 5601
      to_port          = 5601
      protocol         = "tcp"
      cidr_blocks      = [var.vpc_cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }

  ]

  tags = {
    Name = "logging Security Group"
  }
}

# Create an EC2 instance for ELK 
resource "aws_instance" "logging_instance" {
  ami                         = var.ubuntu_ami
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  subnet_id                   = var.logging_subnet_id
  vpc_security_group_ids      = [aws_security_group.logging_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = file("${path.module}/logging.sh")

  tags = {
    Name = "logging_instance"
  }
}

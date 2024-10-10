# Bastion SG
resource "aws_security_group" "database_sg" {
  name        = "Database_SG"
  description = "Security Group for Database created by terraform"
  vpc_id      = var.vpc_id

  ingress = [
    {
      description      = "allow BE connect"
      from_port        = 3306
      to_port          = 3306
      protocol         = "tcp"
      cidr_blocks      = var.backend_subnet_cidrs
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "allow Bastion SSH"
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
  ]

  tags = {
    Name = "Database Security Group"

  }
}

resource "aws_network_interface" "database_ni" {
  subnet_id       = var.database_subnet_ids[0]
  private_ips     = [var.private_ip]
  security_groups = [aws_security_group.database_sg.id]
  tags = {
    Name        = "db_ni"
    Description = "network interface for database instance"
  }
}

resource "aws_instance" "database_instance" {
  ami                  = var.ubuntu_ami
  instance_type        = var.instance_type
  key_name             = var.ssh_key_name
  iam_instance_profile = aws_iam_instance_profile.backup.name
  user_data            = file("${path.module}/dbinstance.sh")

  network_interface {
    network_interface_id = aws_network_interface.database_ni.id
    device_index         = 0
  }

  tags = {
    Name = "Database instance creating by terraform"
  }

  depends_on = [aws_security_group.database_sg, aws_network_interface.database_ni]
}

# Create an S3 bucket
resource "aws_s3_bucket" "backup" {
  bucket = "shopizer-database-backup-bucket" # replace with your bucket name
}

# Create an IAM policy to allow writing to the S3 bucket
resource "aws_iam_policy" "backup" {
  name        = "DatabaseBackup"
  description = "Allows EC2 instances to write to the backup S3 bucket"

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket"
          ],
          "Resource": [
            "arn:aws:s3:::shopizer-database-backup-bucket",
            "arn:aws:s3:::shopizer-database-backup-bucket/*"
          ]
        }
      ]
    }
  EOF
}

# Create an IAM role for the EC2 instance
resource "aws_iam_role" "backup" {
  name = "DatabaseBackupRole"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {"Service": "ec2.amazonaws.com"},
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = aws_iam_policy.backup.arn
}

# Create an instance profile for the EC2 instance
resource "aws_iam_instance_profile" "backup" {
  name = "DatabaseBackupProfile"
  role = aws_iam_role.backup.name
}


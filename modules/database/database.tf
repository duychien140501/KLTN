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
    },
    {
      description      = "allow logstash port 5044"
      from_port        = 5044
      to_port          = 5044
      protocol         = "tcp"
      cidr_blocks      = [var.vpc_cidr]
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
  user_data            = <<-EOF
#!/bin/bash
# Install mysql
echo "mysql-server mysql-server/root_password password root" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password root" | sudo debconf-set-selections

wget https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.15-1_all.deb

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

sudo systemctl start mysql
sudo systemctl enable mysql

sudo apt-get update -y
sudo apt-get install apt-transport-https -y
sudo wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list

sudo apt-get update -y
sudo apt-get install filebeat -y
sudo apt-get update -y

sudo systemctl enable filebeat
sudo systemctl start filebeat

sudo cat > /etc/filebeat/filebeat.yml <<- 'EOM'
# ============================== Filebeat inputs ===============================
filebeat.inputs:
- type: filestream
  id: mysql
  enabled: true
  paths:
    - /var/log/mysql/*.log
  tags: ["mysql"]
  
# ======================= Elasticsearch template setting =======================
setup.template.settings:
  index.number_of_shards: 1

# ------------------------------ Logstash Output -------------------------------
output.logstash:
   #The Logstash hosts
  hosts: ["${var.logging_private_ip}:5044"]
EOM

sudo systemctl restart filebeat

rm mysql-apt-config_0.8.15-1_all.deb

# create database, username, password
sudo mysql -u root -p"root" -e "CREATE USER 'shopizer'@'%' IDENTIFIED BY 'shopizer';"
sudo mysql -u root -p"root" -e "CREATE DATABASE SALESMANAGER;"
sudo mysql -u root -p"root" -e "GRANT ALL PRIVILEGES ON *.* TO 'shopizer'@'%';"
sudo mysql -u root -p"root" -e "FLUSH PRIVILEGES;"

# allow remote access
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# backup database
sudo apt install unzip -y
sudo apt update -y

sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install

sudo mkdir -p ./backupdb
cd ./backupdb
sudo touch ./backupdb.sh
sudo chmod +x ./backupdb.sh

sudo cat > ./backupdb.sh <<- 'EOM'
#!/bin/bash

# MySQL database credentials
DB_USER=${var.DB_USER}
DB_PASS=${var.DB_PASS}

# Timestamp for backup filename
TIMESTAMP=$(date +"%Y%m%d")

# S3 bucket name
S3_BUCKET="shopizer-database-backup"

# Dump MySQL database
BACKUP_FILE="./shopizer-backup-$TIMESTAMP.sql"
mysqldump -u$DB_USER -p$DB_PASS SALESMANAGER > $BACKUP_FILE

# Upload to S3
aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/

rm $BACKUP_FILE
EOM

crontab -l > ./cronbackupdb
sudo cat >> ./cronbackupdb <<- 'EOM'
# backup database everyday at 1:00 AM
0 1 * * * /backupdb/backupdb.sh
EOM
crontab ./cronbackupdb

    EOF

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
  bucket = "shopizer-database-backup" 
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
            "arn:aws:s3:::shopizer-database-backup",
            "arn:aws:s3:::shopizer-database-backup/*"
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


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
  user_data              = <<-EOF
#!/bin/bash

# Change default port
echo "Change default port"

sudo systemctl restart sshd

# Install docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo rm -rf /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$UBUNTU_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo service docker start
sudo groupadd docker
sudo usermod -aG docker $USER
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R 
sudo chmod g+rwx "$HOME/.docker" -R
sudo newgrp docker
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo service docker restart

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
  id: backend
  enabled: true
  paths:
    - /var/log/shopizer.log
  tags: ["backend"]
- type: filestream
  id: be-container
  enabled: true
  paths:
    - /get-log-container/container-log.log
  tags: ["be-container"]

# ======================= Elasticsearch template setting =======================
setup.template.settings:
  index.number_of_shards: 1

# ------------------------------ Logstash Output -------------------------------
output.logstash:
   #The Logstash hosts
  hosts: ["${var.logging_private_ip}:5044"]
EOM

sudo systemctl restart filebeat


# Setup backend
mkdir -p /var/log/
docker pull duychien1405/shopizer-server:1.1

sudo docker run -d \
-p 8080:8080 \
--restart always \
-v /var/log:/opt/app/logs \
--name shopizer-server \
duychien1405/shopizer-server:1.1

# setup cloudwatch agent
sudo apt-get -y install collectd
sudo apt-get -y update

sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

cat > amazon-cloudwatch-agent.json <<- 'EOM'
{
	"agent": {
		"metrics_collection_interval": 20,
		"run_as_user": "root"
	},
	"logs": {
		"logs_collected": {
			"files": {
				"collect_list": [
					{
						"file_path": "/var/log/shopizer.log",
						"log_group_name": "backend.log",
						"log_stream_name": "{instance_id}",
						"retention_in_days": -1
					}
				]
			}
		}
	},
	"metrics": {
		"aggregation_dimensions": [
			[
				"InstanceId"
			]
		],
		"append_dimensions": {
			"AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
			"ImageId": "$${aws:ImageId}",
			"InstanceId": "$${aws:InstanceId}",
			"InstanceType": "$${aws:InstanceType}"
		},
		"metrics_collected": {
			"collectd": {
				"metrics_aggregation_interval": 20
			},
			"disk": {
				"measurement": [
					"used_percent"
				],
				"metrics_collection_interval": 20,
				"resources": [
					"*"
				]
			},
			"mem": {
				"measurement": [
					"mem_used_percent"
				],
				"metrics_collection_interval": 20
			},
      "cpu": {
        "measurement": [
          "cpu_usage_user",
          "cpu_usage_idle",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 20,
        "totalcpu": true,
        "resources": [
          "*"
        ]
      },
			"statsd": {
				"metrics_aggregation_interval": 20,
				"metrics_collection_interval": 20,
				"service_address": ":8125"
			}
		}
	}
}
EOM

sudo mkdir -p /get-log-container/
sudo touch /get-log-container/log-container.sh
sudo chmod +x /get-log-container/log-container.sh

sudo cat > /get-log-container/log-container.sh <<- 'EOM'
#!/bin/bash
sudo docker logs shopizer-server > /get-log-container/container-log.log
EOM
sudo chmod +x /get-log-container/container-log.log

sudo crontab -l > /get-log-container/crontab
sudo cat >> /get-log-container/crontab <<- 'EOM'
*/5 * * * * /get-log-container/log-container.sh
EOM
crontab /get-log-container/crontab

sudo mkdir -p  /usr/share/collectd/
sudo touch /usr/share/collectd/types.db
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:amazon-cloudwatch-agent.json -s

  EOF

  tags = {
    Name = "Backend ${count.index + 1} creating by terraform"
  }

  depends_on = [aws_security_group.backend_sg]
}

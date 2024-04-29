# Frontend SG
resource "aws_security_group" "frontend-sg" {
  name        = "Frontend-SG"
  description = "Security Group for Frontend created by terraform"
  vpc_id      = var.vpc-id

  ingress = [
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
    },
    {
      description      = "Allow from fe-alb"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.fe-alb-sg.id]
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
    Name = "Frontend Security Group"
  }

  depends_on = [aws_security_group.fe-alb-sg]

}

# log group
resource "aws_cloudwatch_log_group" "fe-log-group" {
  name = "fe-access.log"
}

# frontend instance
resource "aws_instance" "frontend" {
  count                  = length(var.frontend-subnet-ids)
  ami                    = var.ubuntu-ami
  instance_type          = "t2.micro"
  key_name               = var.ssh-key-name
  subnet_id              = var.frontend-subnet-ids[count.index]
  vpc_security_group_ids = [aws_security_group.frontend-sg.id]
  iam_instance_profile   = var.cloudwatch_instance_profile_name
  user_data              = <<-EOF
    #!/bin/bash
    echo "Change default username"
    user=${var.default-name}
    usermod  -l $user ubuntu
    groupmod -n $user ubuntu
    usermod  -d /home/$user -m $user
    if [ -f /etc/sudoers.d/90-cloudimg-ubuntu ]; then
    mv /etc/sudoers.d/90-cloudimg-ubuntu /etc/sudoers.d/90-cloud-init-users
    fi
    perl -pi -e "s/ubuntu/$user/g;" /etc/sudoers.d/90-cloud-init-users

    echo "Change default port"
    sudo perl -pi -e 's/^#?Port 22$/Port ${var.default-ssh-port}/' /etc/ssh/sshd_config service
    sudo systemctl restart sshd

    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo rm -rf /etc/apt/keyrings/docker.gpg
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

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
    newgrp docker
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    sudo service docker restart

    sudo mkdir -p /var/log/nginx

    docker run -d --restart always \
    -e "APP_MERCHANT=DEFAULT" \
    -e "APP_BASE_URL=http://${var.alb-be-dns}:8080" \
    -p 80:80 \
    -v /var/log/nginx:/var/log/nginx \
    --name shopizer_shop \
    duychien1405/shopizer-fe:1.2

    # docker running
    while [ "$(sudo docker container inspect -f {{.State.Running}} shopizer_shop)" != "true" ]; do 
        echo "running"
        sleep 1
    done

    # nginx log format
    sudo docker exec shopizer_shop /bin/sh -c "sed -i 's/\(\"\\\$request\"\)/\"\\\$request_time\" \1/' /etc/nginx/nginx.conf"
    sudo docker exec shopizer_shop /bin/sh -c "nginx -s reload"
    sudo docker restart shopizer_shop

    # setup cloudwatch agent
    sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

    sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

    cat > amazon-cloudwatch-agent.json <<- 'EOM'
    {
      "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/nginx/access.log",
                "log_group_name": "fe-access.log",
                "log_stream_name": "{instance_id}",
                "retention_in_days": 30
              },
              {
                "file_path": "/var/log/nginx/error.log",
                "log_group_name": "fe-error.log",
                "log_stream_name": "{instance_id}",
                "retention_in_days": 30
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
            "metrics_aggregation_interval": 60
          },
          "disk": {
            "measurement": [
              "used_percent"
            ],
            "metrics_collection_interval": 60,
            "resources": [
              "*"
            ]
          },
          "mem": {
            "measurement": [
              "mem_used_percent"
            ],
            "metrics_collection_interval": 60
          },
          "statsd": {
            "metrics_aggregation_interval": 60,
            "metrics_collection_interval": 30,
            "service_address": ":8125"
          }
        }
      }
    }
    EOM

    sudo mkdir -p  /usr/share/collectd/
    sudo touch /usr/share/collectd/types.db
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:amazon-cloudwatch-agent.json -s

          EOF

  tags = {
    Name = "Frontend ${count.index + 1} creating by terraform"
  }

  depends_on = [aws_security_group.frontend-sg]
}
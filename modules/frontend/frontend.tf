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

# create target group
resource "aws_lb_target_group" "frontend-tg" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc-id
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

}

# create target attachment
resource "aws_lb_target_group_attachment" "attach-frontend" {
  count            = length(aws_instance.frontend)
  target_group_arn = aws_lb_target_group.frontend-tg.arn
  target_id        = aws_instance.frontend[count.index].id
  port             = 80
}

# create listener
resource "aws_lb_listener" "fe_listener" {
  load_balancer_arn = aws_lb.fe-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend-tg.arn
  }

  depends_on = [aws_lb.fe-alb, aws_lb_target_group.frontend-tg]
}

# Launch Template for Frontend Instances
resource "aws_launch_template" "frontend" {
  name_prefix   = "frontend-template-"
  image_id      = "ami-0fc5d935ebf8bc3bc" 
  instance_type = "t2.micro"
  key_name      = var.ssh-key-name
  vpc_security_group_ids = [aws_security_group.frontend-sg.id]
}

# Auto Scaling Group for Frontend Instances
resource "aws_autoscaling_group" "frontend" {
  desired_capacity     = 0
  max_size             = 2
  min_size             = 0
  vpc_zone_identifier  = var.frontend-subnet-ids 
  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "FE created by Auto Scale"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy for Scaling Up
resource "aws_autoscaling_policy" "frontend_scale_up" {
  name                   = "frontend-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}

# Auto Scaling Policy for Scaling Down
resource "aws_autoscaling_policy" "frontend_scale_down" {
  name                   = "frontend-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}

# CloudWatch Metric Alarm for Scaling Up
resource "aws_cloudwatch_metric_alarm" "frontend_high_request_count" {
  alarm_name                = "high-request-count"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "RequestCountPerTarget"
  namespace                 = "AWS/ApplicationELB"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1000"
  alarm_description         = "This metric monitors high request count for frontend"
  dimensions = {
    "LoadBalancer" = aws_lb.fe-alb.arn_suffix
    "TargetGroup"  = aws_lb_target_group.frontend-tg.arn_suffix
  }
  alarm_actions             = [aws_autoscaling_policy.frontend_scale_up.arn]
}

# CloudWatch Metric Alarm for Scaling Down
resource "aws_cloudwatch_metric_alarm" "frontend_low_request_count" {
  alarm_name                = "low-request-count"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "RequestCountPerTarget"
  namespace                 = "AWS/ApplicationELB"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "500"
  alarm_description         = "This metric monitors low request count for frontend"
  dimensions = {
    "LoadBalancer" = aws_lb.fe-alb.arn_suffix
    "TargetGroup"  = aws_lb_target_group.frontend-tg.arn_suffix
  }
  alarm_actions             = [aws_autoscaling_policy.frontend_scale_down.arn]
}
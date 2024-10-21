#!/bin/bash
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
sudo newgrp docker
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo service docker restart

sudo apt-get update -y
apt-get install apt-transport-https -y
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
  id: adm-access
  enabled: true
  paths:
    - /var/log/nginx/adm-access.log
  tags: ["adm-access"]
- type: filestream
  id: adm-error
  enabled: true
  paths:
    - /var/log/nginx/adm-error.log
  tags: ["adm-error"]

# ======================= Elasticsearch template setting =======================
setup.template.settings:
  index.number_of_shards: 1

# ------------------------------ Logstash Output -------------------------------
output.logstash:
   #The Logstash hosts
  hosts: ["${var.logging_private_ip}:5044"]
EOM

sudo systemctl restart filebeat

sudo mkdir -p /var/log/nginx
docker pull duychien1405/shopizer-fe-admin:1.3

sudo docker run -d  --restart always \
-e APP_BASE_URL=http://${var.alb_be_dns}:8080  \
-p 82:80 -v /var/log/nginx:/var/log/nginx  \
--name shopizer_admin \
duychien1405/shopizer-fe-admin:1.3

# docker running
while [ "$(sudo docker container inspect -f {{.State.Running}} shopizer_admin)" != "true" ]; do 
    sleep 1
done

# nginx log format
sudo docker exec shopizer_admin /bin/sh -c "sed -i 's/\(\"\\\$request\"\)/\"\\\$request_time\" \1/' /etc/nginx/nginx.conf"
sudo docker exec shopizer_admin /bin/sh -c "nginx -s reload"
sudo docker restart shopizer_admin

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
            "log_group_name": "adm-access.log",
            "log_stream_name": "{instance_id}",
            "retention_in_days": -1
            },
            {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "adm-error.log",
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
        "metrics_collection_interval": 10,
        "service_address": ":8125"
        }
    }
    }
}
EOM

sudo mkdir -p  /usr/share/collectd/
sudo touch /usr/share/collectd/types.db
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:amazon-cloudwatch-agent.json -s

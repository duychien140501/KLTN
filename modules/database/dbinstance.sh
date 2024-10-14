#!/bin/bash

sudo systemctl restart sshd

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
  id: my-filestream-id
  enabled: true
  paths:
    - /var/log/mysql/*.log

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

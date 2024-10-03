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

rm mysql-apt-config_0.8.15-1_all.deb

# create database, username, password
sudo mysql -u root -p"root" -e "CREATE USER 'shopizer'@'%' IDENTIFIED BY 'shopizer';"
sudo mysql -u root -p"root" -e "CREATE DATABASE SALESMANAGER;"
sudo mysql -u root -p"root" -e "GRANT ALL PRIVILEGES ON *.* TO 'shopizer'@'%';"
sudo mysql -u root -p"root" -e "FLUSH PRIVILEGES;"

# allow remote access
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

#!/bin/bash

# Change default username
echo "Change default username"
user=${var.default-name}
usermod  -l $user ubuntu
groupmod -n $user ubuntu
usermod  -d /home/$user -m $user
if [ -f /etc/sudoers.d/90-cloudimg-ubuntu ]; then
mv /etc/sudoers.d/90-cloudimg-ubuntu /etc/sudoers.d/90-cloud-init-users
fi
perl -pi -e "s/ubuntu/$user/g;" /etc/sudoers.d/90-cloud-init-users

# Change default port
echo "Change default port"
sudo perl -pi -e 's/^#?Port 22$/Port 2222/' /etc/ssh/sshd_config service
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
sudo mysql -u root -p"root" -e "GRANT ALL PRIVILEGES ON SALESMANAGER.* TO 'shopizer'@'%';"
sudo mysql -u root -p"root" -e "FLUSH PRIVILEGES;"

# allow remote access
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

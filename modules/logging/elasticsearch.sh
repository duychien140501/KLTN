# sudo apt-get update
# sudo apt-get install -y apt-transport-https default-jdk

# # Install Elasticsearch
# wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
# echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
# sudo apt-get update && sudo apt-get install elasticsearch=8.15.0

# # Configure Elasticsearch to start on boot
# sudo /bin/systemctl daemon-reload
# sudo /bin/systemctl enable elasticsearch.service

# # Start Elasticsearch
# sudo systemctl start elasticsearch.service
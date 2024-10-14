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

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y
sudo service docker start
sudo groupadd docker
sudo usermod -aG docker $USER
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
sudo newgrp docker
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo service docker restart

sudo mkdir -p ./logging
cd ./logging
sudo touch .env logstash.conf logstash.yml docker-compose.yml
sudo chmod +x .env docker-compose.yml logstash.conf logstash.yml

sudo cat << 'EOF' > ./.env 
# Password for the 'elastic' user (at least 6 characters)
ELASTIC_PASSWORD=elastic

# Password for the 'kibana_system' user (at least 6 characters)
KIBANA_PASSWORD=kibana

# Version of Elastic products
STACK_VERSION=8.15.2

# Set the cluster name
CLUSTER_NAME=elasticsearch

# Set to 'basic' or 'trial' to automatically start the 30-day trial
LICENSE=basic

# Port to expose Elasticsearch HTTP API to the host
ES_PORT=9200

# Port to expose Kibana to the host
KIBANA_PORT=5601

# Increase or decrease based on the available host memory (in bytes)
ES_MEM_LIMIT=1610612736
KB_MEM_LIMIT=1073741824
LS_MEM_LIMIT=1073741824

# SAMPLE Predefined Key only to be used in POC environments
ENCRYPTION_KEY=WCUDv4T05kvv1mhedmgP5olbW3M+dCF+e7PIpmGZEnb1Jt8GFdGipO403YMs+fbf
EOF

sudo cat << 'EOF' >  logstash.conf
input {
  beats {
    host => "0.0.0.0"
    port => 5044
  }
}

filter {}

output {
  if "fe-access" in [tags] {
    elasticsearch {
      index => "fe-access-%{+YYYY.MM.dd}"
      hosts => ["https://es01:9200"]
      user => "elastic"
      password => "elastic"
      ssl_enabled => true
      cacert => "/usr/share/logstash/certs/ca/ca.crt"
    }
  } 
  if "fe-error" in [tags] {
    elasticsearch {
      index => "fe-error-%{+YYYY.MM.dd}"
      hosts => ["https://es01:9200"]
      user => "elastic"
      password => "elastic"
      ssl_enabled => true
      cacert => "/usr/share/logstash/certs/ca/ca.crt"
    }
  }
  if "adm-error" in [tags] {
    elasticsearch {
      index => "adm-error-%{+YYYY.MM.dd}"
      hosts => ["https://es01:9200"]
      user => "elastic"
      password => "elastic"
      ssl_enabled => true
      cacert => "/usr/share/logstash/certs/ca/ca.crt"
    }
  }
  if "adm-access" in [tags] {
    elasticsearch {
      index => "adm-access-%{+YYYY.MM.dd}"
      hosts => ["https://es01:9200"]
      user => "elastic"
      password => "elastic"
      ssl_enabled => true
      cacert => "/usr/share/logstash/certs/ca/ca.crt"
    }
  }
  if "backend" in [tags] {
    elasticsearch {
      index => "backend-%{+YYYY.MM.dd}"
      hosts => ["https://es01:9200"]
      user => "elastic"
      password => "elastic"
      ssl_enabled => true
      cacert => "/usr/share/logstash/certs/ca/ca.crt"
    }
  }
  if "mysql" in [tags] {
    elasticsearch {
      index => "mysql-%{+YYYY.MM.dd}"
      hosts => ["https://es01:9200"]
      user => "elastic"
      password => "elastic"
      ssl_enabled => true
      cacert => "/usr/share/logstash/certs/ca/ca.crt"
    }
  }

  # elasticsearch {
  #   index => "logstash-%{+YYYY.MM.dd}"
  #   hosts => ["https://es01:9200"]
  #   user => "elastic"
  #   password => "elastic"
  #   ssl_enabled => true
  #   cacert => "/usr/share/logstash/certs/ca/ca.crt"
  # }
}
EOF

sudo cat << 'EOF' > logstash.yml
http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.hosts: [ "http://es01:9200" ]
EOF

sudo cat << 'EOF' > ./docker-compose.yml
version: "3.8"

volumes:
 certs:
   driver: local
 esdata01:
   driver: local
 esdata02:
   driver: local
 esdata03:
   driver: local
 kibanadata:
   driver: local
 logstashdata01:
   driver: local

networks:
 default:
   name: elastic
   external: false

services:
 setup:
   image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
   volumes:
     - certs:/usr/share/elasticsearch/config/certs
   user: "0"
   command: >
     bash -c '
       if [ x${ELASTIC_PASSWORD} == x ]; then
         echo "Set the ELASTIC_PASSWORD environment variable in the .env file";
         exit 1;
       elif [ x${KIBANA_PASSWORD} == x ]; then
         echo "Set the KIBANA_PASSWORD environment variable in the .env file";
         exit 1;
       fi;
       if [ ! -f config/certs/ca.zip ]; then
         echo "Creating CA";
         bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
         unzip config/certs/ca.zip -d config/certs;
       fi;
       if [ ! -f config/certs/certs.zip ]; then
         echo "Creating certs";
         echo -ne \
         "instances:\n"\
         "  - name: es01\n"\
         "    dns:\n"\
         "      - es01\n"\
         "      - localhost\n"\
         "    ip:\n"\
         "      - 127.0.0.1\n"\
         > config/certs/instances.yml;
         bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
         unzip config/certs/certs.zip -d config/certs;
       fi;
       echo "Setting file permissions"
       chown -R root:root config/certs;
       find . -type d -exec chmod 750 \{\} \;;
       find . -type f -exec chmod 640 \{\} \;;
       echo "Waiting for Elasticsearch availability";
       until curl -s --cacert config/certs/ca/ca.crt https://es01:9200 | grep -q "missing authentication credentials"; do sleep 30; done;
       echo "Setting kibana_system password";
       until curl -s -X POST --cacert config/certs/ca/ca.crt -u "elastic:${ELASTIC_PASSWORD}" -H "Content-Type: application/json" https://es01:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;
       echo "All done!";
     '
   healthcheck:
     test: ["CMD-SHELL", "[ -f config/certs/es01/es01.crt ]"]
     interval: 1s
     timeout: 5s
     retries: 120

 es01:
   depends_on:
     setup:
       condition: service_healthy
   image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
   labels:
     co.elastic.logs/module: elasticsearch
   volumes:
     - certs:/usr/share/elasticsearch/config/certs
     - esdata01:/usr/share/elasticsearch/data
   ports:
     - 9201:9200
   environment:
     - node.name=es01
     - cluster.name=${CLUSTER_NAME}
     - discovery.type=single-node
     - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
     - bootstrap.memory_lock=true
     - xpack.security.enabled=true
     - xpack.security.http.ssl.enabled=true
     - xpack.security.http.ssl.key=certs/es01/es01.key
     - xpack.security.http.ssl.certificate=certs/es01/es01.crt
     - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
     - xpack.security.transport.ssl.enabled=true
     - xpack.security.transport.ssl.key=certs/es01/es01.key
     - xpack.security.transport.ssl.certificate=certs/es01/es01.crt
     - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
     - xpack.security.transport.ssl.verification_mode=certificate
     - xpack.license.self_generated.type=${LICENSE}
   mem_limit: ${ES_MEM_LIMIT}
   ulimits:
     memlock:
       soft: -1
       hard: -1
   healthcheck:
     test:
       [
         "CMD-SHELL",
         "curl -s --cacert config/certs/ca/ca.crt https://localhost:9200 | grep -q 'missing authentication credentials'",
       ]
     interval: 10s
     timeout: 10s
     retries: 120

 kibana:
   depends_on:
     es01:
       condition: service_healthy
   image: docker.elastic.co/kibana/kibana:${STACK_VERSION}
   labels:
     co.elastic.logs/module: kibana
   volumes:
     - certs:/usr/share/kibana/config/certs
     - kibanadata:/usr/share/kibana/data
   ports:
     - ${KIBANA_PORT}:5601
   environment:
     - SERVERNAME=kibana
     - ELASTICSEARCH_HOSTS=https://es01:9200
     - ELASTICSEARCH_USERNAME=kibana_system
     - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
     - ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES=config/certs/ca/ca.crt
     - XPACK_SECURITY_ENCRYPTIONKEY=${ENCRYPTION_KEY}
     - XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY=${ENCRYPTION_KEY}
     - XPACK_REPORTING_ENCRYPTIONKEY=${ENCRYPTION_KEY}
   mem_limit: ${KB_MEM_LIMIT}
   healthcheck:
     test:
       [
         "CMD-SHELL",
         "curl -s -I http://localhost:5601 | grep -q 'HTTP/1.1 302 Found'",
       ]
     interval: 10s
     timeout: 10s
     retries: 120

 logstash:
   depends_on:
     es01:
       condition: service_healthy
     kibana:
       condition: service_healthy
   image: docker.elastic.co/logstash/logstash:${STACK_VERSION}
   labels:
     co.elastic.logs/module: logstash
   user: root
   volumes:
     - logstashdata01:/usr/share/logstash/data
     - certs:/usr/share/logstash/certs
     - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf:ro
   environment:
     - NODE_NAME="logstash"
     - xpack.monitoring.enabled=false
     - ELASTIC_USER=elastic
     - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
     - ELASTIC_HOSTS=https://es01:9200
   command: logstash -f /usr/share/logstash/pipeline/logstash.conf
   ports:
     - 5044:5044
   mem_limit: ${LS_MEM_LIMIT}
EOF

sudo docker compose up -d
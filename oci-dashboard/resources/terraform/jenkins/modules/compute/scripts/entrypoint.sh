#!/bin/bash

apt update && apt upgrade -y 
apt install docker.io cmake -y
curl -O -J -L https://github.com/docker/compose/releases/download/v2.11.2/docker-compose-linux-x86_64
chmod +x docker-compose-linux-x86_64
cp ./docker-compose-linux-x86_64 /usr/bin/docker-compose
rm -f ./docker-compose-linux-x86_64
chmod 666 /var/run/docker.sock

cd /home/ubuntu
git clone https://github.com/AhmedFatir/jenkins.git
git config --global --add safe.directory /jenkins
chown -R ubuntu:ubuntu /home/ubuntu/jenkins

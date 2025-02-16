#!/bin/bash
sudo apt-get update
sudo apt-get install -y docker.io cmake
curl -O -J -L https://github.com/docker/compose/releases/download/v2.11.2/docker-compose-linux-x86_64
chmod +x docker-compose-linux-x86_64
sudo cp ./docker-compose-linux-x86_64 /usr/bin/docker-compose
sudo systemctl enable docker
sudo systemctl start docker
git clone https://github.com/AhmedFatir/jenkins.git
cd jenkins
sudo docker-compose up --build -d

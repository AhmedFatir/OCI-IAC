#!/bin/bash

# Add Docker's official GPG key
apt-get update
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update
apt-get install cmake docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
chmod 666 /var/run/docker.sock

# build and run the Jenkins container
cd /home/ubuntu
git clone https://github.com/AhmedFatir/jenkins.git
git config --global --add safe.directory /jenkins
chown -R ubuntu:ubuntu /home/ubuntu/jenkins

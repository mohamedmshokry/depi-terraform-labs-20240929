#!/bin/bash

sudo apt update -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo usermod -aG docker ubuntu
newgrp docker

# Install Jenkins
sudo mkdir /home/ubuntu/jenkins_space
sudo chown ubuntu:ubuntu /home/ubuntu/jenkins_space
docker run -d --network host -v /home/ubuntu/jenkins_space:/var/jenkins_home jenkins:2.60.3

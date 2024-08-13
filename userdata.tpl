#!/bin/bash
sudo yum update -y &&
sudo yum install -y &&
sudo amazon-linux-extras install docker -y &&
sudo yum install docker-cli containerd.io -y &&
sudo usermod -aG docker ec2-user
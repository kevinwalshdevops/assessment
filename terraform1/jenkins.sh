#!/bin/bash
sudo yum -y update
sudo amazon-linux-extras install epel -y 

echo "Install Java JDK 8"
sudo yum remove -y java
sudo yum install java-1.8.0-openjdk-devel

echo "Install Maven"
sudo yum install -y maven 

echo "Install git"
sudo yum install -y git

echo "Install Docker engine"
sudo yum update -y
sudo yum install docker -y
sudo sudo chkconfig docker on

echo "Install Jenkins"
curl --silent --location http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo | sudo tee /etc/yum.repos.d/jenkins.repo
sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
sudo yum install -y jenkins
sudo usermod -a -G docker jenkins
sudo chkconfig jenkins on

echo "Start Docker & Jenkins services"
sudo service docker start
sudo service jenkins start
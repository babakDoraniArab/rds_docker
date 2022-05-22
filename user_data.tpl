#!/bin/bash
db_username=${db_username}
db_user_password=${db_user_password}
db_name=${db_name}
db_RDS=${db_RDS}


sudo yum update -y
sudo yum install -y polkit
sudo yum install -y git
git clone https://github.com/amir-akhavans/ecs-project.git
sudo yum install -y htop
mv ecs-project/* ./

 mv ./docker/web/Dockerfile ./
sudo yum install -y docker
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo docker build -t fixably .
sudo docker run -e MYSQL_DATABASE=$db_name -e MYSQL_USERNAME=$db_username -e MYSQL_PASSWORD=$db_user_password -e MYSQL_HOST=$db_RDS --name project -p 8080:80 fixably

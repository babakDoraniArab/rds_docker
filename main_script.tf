# provider "aws" {

#   region                  = var.region
#   shared_credentials_file = var.shared_credentials_file
# }


# Create VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block           = var.VPC_cidr
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  enable_classiclink   = "false"
  instance_tenancy     = "default"


}

# Create Public Subnet for EC2
resource "aws_subnet" "prod-subnet-public-1" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone       = var.AZ1

}

# Create Private subnet for RDS
resource "aws_subnet" "prod-subnet-private-1" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = var.subnet2_cidr
  map_public_ip_on_launch = "false" //it makes private subnet
  availability_zone       = var.AZ2

}

# Create second Private subnet for RDS
resource "aws_subnet" "prod-subnet-private-2" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = var.subnet3_cidr
  map_public_ip_on_launch = "false" //it makes private subnet
  availability_zone       = var.AZ3

}



# Create IGW for internet connection 
resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.prod-vpc.id

}

# Creating Route table 
resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.prod-igw.id
  }


}


# Associating route tabe to public subnet
resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id      = aws_subnet.prod-subnet-public-1.id
  route_table_id = aws_route_table.prod-public-crt.id
}



//security group for EC2

resource "aws_security_group" "ec2_allow_rule" {


  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.prod-vpc.id
  tags = {
    Name = "allow ssh,http,https"
  }
}


# Security group for RDS
resource "aws_security_group" "RDS_allow_rule" {
  vpc_id = aws_vpc.prod-vpc.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ec2_allow_rule.id}"]
  }
  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow ec2"
  }

}

# Create RDS Subnet group
resource "aws_db_subnet_group" "RDS_subnet_grp" {
  subnet_ids = ["${aws_subnet.prod-subnet-private-1.id}", "${aws_subnet.prod-subnet-private-2.id}"]
}

# Create RDS instance
resource "aws_db_instance" "wordpressdb" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = var.instance_class
  db_subnet_group_name   = aws_db_subnet_group.RDS_subnet_grp.id
  vpc_security_group_ids = ["${aws_security_group.RDS_allow_rule.id}"]
  db_name                = var.MYSQL_DATABASE
  username               = var.MYSQL_USERNAME
  password               = var.MYSQL_PASSWORD
  # db                     = var.MYSQL_HOST
  # database                     = var.MYSQL_HOST
  skip_final_snapshot = true
}

# change USERDATA varible value after grabbing RDS endpoint info
# data "template_file" "user_data" {
#   template = file("./user_data.tpl")
#   vars = {
#     MYSQL_USERNAME      = var.MYSQL_USERNAME
#     MYSQL_PASSWORD      = var.MYSQL_PASSWORD
#     MYSQL_DATABASE      = var.MYSQL_DATABASE
#     MYSQL_HOST          = var.MYSQL_HOST
# db_RDS              = aws_db_instance.wordpressdb.endpoint
#   }
# }
data "template_file" "user_data" {
  # template = file("./user_data.tpl")
  template = "${file("./user_data.tpl")}"
  vars = {
    db_username      = var.MYSQL_USERNAME
    db_user_password = var.MYSQL_PASSWORD
    db_name          = var.MYSQL_DATABASE
    db_RDS           = aws_db_instance.wordpressdb.endpoint
  }
}
data "template_file" "init" {
  template = "${file("${path.module}/init.tpl")}"
  vars = {
    consul_address = "${aws_instance.consul.private_ip}"
  }
}

# Create EC2 ( only after RDS is provisioned)
resource "aws_instance" "wordpressec2" {
  ami             = data.aws_ami.linux2.id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.prod-subnet-public-1.id
  security_groups = ["${aws_security_group.ec2_allow_rule.id}"]
  # user_data       = data.template_file.user_data.rendered
  # key_name        = aws_key_pair.mykey-pair.id
  # user_data = data.template_file.user_data.rendered
  #babak
  key_name = var.key_name
  tags = {
    Name = "Wordpress.web"
  }

  depends_on = [aws_db_instance.wordpressdb]
}

// Sends your public key to the instance
# resource "aws_key_pair" "mykey-pair" {
#   key_name   = "mykey-pair"
#   public_key = file(var.PUBLIC_KEY_PATH)
# }

# creating Elastic IP for EC2
resource "aws_eip" "eip" {
  instance = aws_instance.wordpressec2.id

}

output "IP" {
  value = aws_eip.eip.public_ip
}
output "RDS-Endpoint" {
  value = aws_db_instance.wordpressdb.endpoint
}

# output "INFO" {
#   value = "AWS Resources and Wordpress has been provisioned. Go to http://${aws_eip.eip.public_ip}"
# }

# resource "null_resource" "Wordpress_Installation_Waiting" {
#   connection {
#     type        = "ssh"
#     user        = var.IsUbuntu ? "ubuntu" : "ec2-user"
#     private_key = file(var.PRIV_KEY_PATH)
#     host        = aws_eip.eip.public_ip
#   }


#   provisioner "remote-exec" {
#     inline = ["sudo tail -f -n0 /var/log/cloud-init-output.log| grep -q 'WordPress Installed'"]

#   }
# }







################################
## wordpressec2 output 
################################

output "wordpressec2_arn" {
  value     = aws_instance.wordpressec2.arn
  sensitive = false
}
output "wordpressec2_private_dns" {
  value     = aws_instance.wordpressec2.private_dns
  sensitive = false
}
output "wordpressec2_public_dns" {
  value     = aws_instance.wordpressec2.public_dns
  sensitive = false
}
output "wordpressec2_public_ip" {
  value     = aws_instance.wordpressec2.public_ip
  sensitive = false
}
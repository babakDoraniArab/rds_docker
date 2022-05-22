
variable "MYSQL_USERNAME" {
  default = "root"
}

variable "MYSQL_PASSWORD" {
  default = "12345678"
}

variable "MYSQL_DATABASE" {
  default = "hello"
}

# variable "MYSQL_HOST" {
#   default = "mysql"
# }

variable "region" {
  default = "eu-west-1"
}


# variable "shared_credentials_file" {
#   default = 
# }
variable "IsUbuntu" {
  type    = bool
  default = false

}
variable "AZ1" {
  default = "eu-west-1a"
}
variable "AZ2" {
  default = "eu-west-1b"
}
variable "AZ3" {
  default = "eu-west-1c"
}
variable "VPC_cidr" {
  default = "10.0.0.0/16"
}
variable "subnet1_cidr" {
  default = "10.0.1.0/24"
}
variable "subnet2_cidr" {
  default = "10.0.2.0/24"
}
variable "subnet3_cidr" {
  default = "10.0.3.0/24"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "instance_class" {
  default = "db.t2.micro"
}
# variable "PUBLIC_KEY_PATH" {
#   default = 
# }
# variable "PRIV_KEY_PATH" {}

################################################################
# babak
################################################################
variable "key_name" {
  default = "Demo2"
}
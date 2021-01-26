###############################
## Rutime Values             ##
###############################
terraform {
    required_version = ">= 0.11"
    backend "s3" {
        bucket = "__tfbucketaccount__"
        key    = "terraform.tfstate"
        region = "__awsregion__"
        features {}
    }
}
###############################
## AWS IaC Components      ##
###############################
provider "aws" {
    region = "__awsregion__"
}
###############################
##   AWS Net Components      ##
###############################
#VPC
resource "aws_vpc" "chall_vpc" {
  cidr_block       = "172.16.43.0/26"
  enable_dns_hostnames = true

  tags = {
    Environment = "Challenge"
  }
}
#Subnets
resource "aws_subnet" "publicsnet" {
  vpc_id     = aws_vpc.chall_vpc.id
  cidr_block = "172.16.43.0/28"
  map_public_ip_on_launch = true

  tags = {
    Environment = "Challenge"
  }
}
resource "aws_subnet" "privatesnet" {
  vpc_id     = aws_vpc.chall_vpc.id
  cidr_block = "172.16.43.16/28"
  map_public_ip_on_launch = true

  tags = {
    Environment = "Challenge"
  }
}
#Internet Gateway
resource "aws_internet_gateway" "chall_igw" {
  vpc_id = aws_vpc.chall_vpc.id

  tags = {
    Environment = "Challenge"
  }
}
#Routing Public Subnet
resource "aws_route_table" "chall_route_public" {
  vpc_id = aws_vpc.chall_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chall_igw.id
  }

  tags = {
    Environment = "Challenge"
  }
}
resource "aws_route_table_association" "chall_route_assoc_public" {
  subnet_id = aws_subnet.publicsnet.id
  route_table_id = aws_route_table.chall_route_public.id
}
resource "aws_eip" "publiceip" {
  vpc = true
}
#NAT Gateway
resource "aws_nat_gateway" "chall_nat" {
  allocation_id = aws_eip.publiceip.id
  subnet_id = aws_subnet.publicsnet.id

  tags = {
    Environment = "Challenge"
  }
}
resource "aws_route_table" "chall_route_nat" {
  vpc_id = aws_vpc.chall_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.chall_nat.id
  }

  tags = {
    Environment = "Challenge"
  }
}
resource "aws_route_table_association" "chall_route_assoc_nat" {
  subnet_id = aws_subnet.privatesnet.id
  route_table_id = aws_route_table.chall_route_nat.id
}

#Security Group 
resource "aws_security_group" "chall_sg" {
  name        = "chall_nat"
  description = "Traffic Control"
  vpc_id      = aws_vpc.chall_vpc.id
  #Incoming
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
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMP"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "Output"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "Challenge"
  }
}
###############################
##   AWS App Components      ##
###############################
#KeyPair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}
#EC2 Instance
resource "aws_instance" "chall_instance" {
  ami = "ami-00ddb0e5626798373"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.privatesnet.id
  key_name = "${aws_key_pair.deployer.id}"
  vpc_security_group_ids = [ "${aws_security_group.chall_sg.id}" ]

  tags = {
    Environment = "Challenge"
  }
  
}
###############################
##   AWS App Components      ##
###############################
#ELB
resource "aws_elb" "chall-elb" {
  name = "chall-elb"
  security_groups = [ "${aws_security_group.chall_sg.id}" ]
  subnets = [ "${aws_subnet.publicsnet.id}"]
  instances = [ "${aws_instance.chall_instance.id}" ]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}
###############################
##   Bonus                   ##
###############################
#TODO
###############################
##   Output                  ##
###############################
output "ELBIP" {
  value = "${aws_elb.chall-elb.dns_name}"
}
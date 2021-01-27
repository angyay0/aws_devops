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
  availability_zone = "us-east-1b"

  tags = {
    Environment = "Challenge"
  }
}
resource "aws_subnet" "privatesnet" {
  vpc_id     = aws_vpc.chall_vpc.id
  cidr_block = "172.16.43.16/28"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1b"

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
#EIP
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
#Routing Public Subnet
resource "aws_route_table" "chall_route_public" {
  vpc_id = aws_vpc.chall_vpc.id

  tags = {
    Environment = "Challenge"
  }
}
resource "aws_route" "chall_pub_route" {
  route_table_id = aws_route_table.chall_route_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.chall_igw.id
}
resource "aws_route_table_association" "chall_route_assoc_public" {
  subnet_id = aws_subnet.publicsnet.id
  route_table_id = aws_route_table.chall_route_public.id
}
#Routing Private Subnet
resource "aws_route_table" "chall_route_nat" {
  vpc_id = aws_vpc.chall_vpc.id

  tags = {
    Environment = "Challenge"
  }
}
resource "aws_route" "chall_priv_route" {
  route_table_id = aws_route_table.chall_route_nat.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.chall_nat.id
}
resource "aws_route_table_association" "chall_route_assoc_nat" {
  subnet_id = aws_subnet.privatesnet.id
  route_table_id = aws_route_table.chall_route_nat.id
}
#Security Groups
resource "aws_security_group" "chall_sg_nat" {
  name        = "chall_nat"
  description = "Traffic Control"
  vpc_id      = aws_vpc.chall_vpc.id
  #Incoming
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.privatesnet.cidr_block}"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.privatesnet.cidr_block}"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Egress
  egress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.chall_vpc.cidr_block}"]
  }
  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "Challenge"
  }
}
resource "aws_security_group" "chall_sg_pub" {
  name        = "challsgpub"
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
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Egress
  egress {
    description = "For Internal"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "Challenge"
  }
}
resource "aws_security_group" "chall_sg_priv" {
  name        = "challsgpriv"
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
    cidr_blocks = ["${aws_vpc.chall_vpc.cidr_block}"]
  }
  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${aws_vpc.chall_vpc.cidr_block}"]
  }
  #Egress
  egress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "Challenge"
  }
}
###############################
##   AWS App Components      ##
###############################
#Jumpbox
resource "aws_instance" "jumpbox" {
    ami = "ami-01ef31f9f39c5aaed"
    instance_type = "t2.micro"
    key_name = "DevOpsKey"
    vpc_security_group_ids = ["${aws_security_group.chall_sg_nat.id}"]
    subnet_id = "${aws_subnet.publicsnet.id}"
    associate_public_ip_address = true
    source_dest_check = false

    tags = {
        Name = "VPC NAT"
        Environment = "Challenge"
    }

  connection {
    type = "ssh"
    user = "ec2-user"
    host = self.public_ip
    private_key = file("DevOpsKey.pem")
  }

  provisioner "file" {
    source = "DevOpsKey.pem"
    destination = "/home/ec2-user/DevOpsKey.pem"
  }

  provisioner "file" {
    source = "showip.conf"
    destination = "/home/ec2-user/showip"
  }
}
resource "aws_eip" "jumboxeip" {
    instance = "${aws_instance.jumpbox.id}"
    vpc = true
}

#EC2 Server Instance
resource "aws_instance" "chall_instance" {
  ami = "ami-00ddb0e5626798373"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.privatesnet.id
  associate_public_ip_address = false
  key_name = "DevOpsKey"
  vpc_security_group_ids = [ "${aws_security_group.chall_sg_priv.id}" ]

  tags = {
    Environment = "Challenge"
  }

  #provisioner "remote-exec" {
  #   inline = [
  #    "chmod 400 DevOpsKey.pem",
  #    "ssh -i \"DevOpsKey.pem\" ubuntu@${self.private_ip}",
  #    "sudo apt-get -y update",
  #    "sudo apt-get -y install nginx",
  #    "sudo service nginx start",
  #    "sudo cp showip /etc/nginx/sites-available/showip",
  #    "sudo rm /etc/nginx/sites-enabled/default",
  #    "sudo service nginx restart"
  #  ]
  #}

}
###############################
##   AWS App Components      ##
###############################
#ELB
resource "aws_elb" "chall-elb" {
  name = "chall-elb"
  security_groups = [ "${aws_security_group.chall_sg_pub.id}" ]
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
##   Output                  ##
###############################
output "ELBIP" {
  value = "${aws_elb.chall-elb.dns_name}"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


provider "aws" {
  region = "ap-southeast-2"
}

# Variables
variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}

variable "IP_ADDR" {}

variable "instance_type" {}


# VPC Resource
resource "aws_vpc" "myapp_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  cidr_block        = var.subnet_cidr_block
  vpc_id            = aws_vpc.myapp_vpc.id
  availability_zone = var.avail_zone
  tags = {
    "Name" = "${var.env_prefix}-subnet"
  }
}

/*resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    "Name" = "${var.env_prefix}-rtb"
  }

}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}*/

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp_vpc.id
  tags = {
    "Name" = "${var.env_prefix}-igw"
  }
}



resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    "Name" = "${var.env_prefix}-main-rtb"
  }
}

resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${var.env_prefix}-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "myapp-server" {
  ami                         = data.aws_ami.latest-amazon-linux-image.id
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.myapp-sg.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  key_name                    = "myKeyPair"
  user_data                   = file("entry-script.sh")

  tags = {
    "Name" = "${var.env_prefix}-server"
  }
}


output "server-public-ip" {
  value = aws_instance.myapp-server.public_ip
}

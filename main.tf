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
variable "cidr_blocks" {
  description = "CIDR Blocks for VPC and Subnet"
  type = list(object({
    cidr_block = string
    name       = string
  }))
  # default     = "10.0.0.0/24"
}


variable "environment" {
  description = "Deployment Environment"

}

variable "avail_zone" {}

# VPC Resource
resource "aws_vpc" "terraform_vpc" {
  cidr_block = var.cidr_blocks[0].cidr_block
  tags = {
    "Name" = var.cidr_blocks[0].name
  }
}


resource "aws_subnet" "dev-frontend" {
  cidr_block        = var.cidr_blocks[1].cidr_block
  vpc_id            = aws_vpc.terraform_vpc.id
  availability_zone = var.avail_zone
  tags = {
    "Name" = var.cidr_blocks[1].name
  }
}

# Data is used for existing resource
data "aws_vpc" "existing_vpc" {
  default = true
}

resource "aws_subnet" "default-subnet-1" {
  cidr_block = "172.31.10.0/24"
  vpc_id     = data.aws_vpc.existing_vpc.id
  tags = {
    "Name" = "${var.environment}-default-frontend-1"
  }

}

output "VPC_ID" {
  value = aws_vpc.terraform_vpc.id
}

output "Default_Subnnet_ID" {
  value = aws_subnet.default-subnet-1.id
}

output "Frontend_Subnet_ID" {
  value = aws_subnet.dev-frontend.id
}

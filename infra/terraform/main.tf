terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "hephaestus-fleet"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for backend
resource "aws_security_group" "hermes_backend" {
  name        = "hermes-backend-sg"
  description = "Security group for Hermes backend"

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: Restrict to your IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hermes-backend"
  }
}

# EC2 instance
resource "aws_instance" "hermes_backend" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = "hermes-backend-key"
  
  vpc_security_group_ids = [aws_security_group.hermes_backend.id]
  subnet_id              = data.aws_subnets.default.ids[0]

  # Use domain_name if provided, otherwise use "_" which accepts any hostname/IP
  user_data = templatefile("${path.module}/user-data.sh", {
    domain_name = var.domain_name != "" ? var.domain_name : "_"
  })

  tags = {
    Name = "hermes-backend"
  }
}

# Get latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Elastic IP (optional but recommended for stable IP)
resource "aws_eip" "hermes_backend" {
  instance = aws_instance.hermes_backend.id
  domain   = "vpc"

  tags = {
    Name = "hermes-backend-eip"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.6.2"
    }
  }
}

variable "name" {
  type        = string
  default     = "kk-launch"
  description = "name of the launch template"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "aws region"
}

provider "aws" {
  # Configuration options
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "allow_tls" {
  name        = var.name
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "TLS HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "TLS SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_launch_template" "example" {
  name = var.name

  block_device_mappings {
    ebs {
      volume_size = 10
    }
    device_name = "/dev/sda1"
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  disable_api_stop        = false
  disable_api_termination = false

  ebs_optimized = false


  image_id = "ami-053b0d53c279acc90"

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t2.small"

  #   key_name = "test"


  #   network_interfaces {
  #     associate_public_ip_address = true
  #   }

  # not to add this ever
  # placement {
  #   availability_zone = "${var.region}a"
  # }

  vpc_security_group_ids = [aws_security_group.allow_tls.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = var.name
    }
  }

  user_data = filebase64("${path.module}/init.sh")
}

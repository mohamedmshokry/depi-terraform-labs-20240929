provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "depi-web-01" {
  ami = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.micro"
}


# resource "aws_security_group" "web-01-sg" {
#   name        = "web-01-sg"
#   description = "Security group for demo ec2 by tarraform"

#   vpc_id = data.aws_vpc.default.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "web-01-sg"
#   }
# }

# resource "aws_instance" "web-01" {
#   ami                    = var.instance_ami
#   instance_type          = var.instance_type
#   vpc_security_group_ids = [aws_security_group.web-01-sg.id]
#   tags = {
#     Name = "web-01"
#   }
# }

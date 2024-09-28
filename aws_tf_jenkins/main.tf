resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "jenkins_vpc"
  }
}


#########################
# Create Public Subnets #
#########################
resource "aws_subnet" "jenkins_subnet_Public_eu-north-1a" {
  vpc_id                                      = aws_vpc.jenkins_vpc.id
  cidr_block                                  = "10.0.1.0/24"
  availability_zone                           = "eu-north-1a"
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = true

  tags = {
    Name = "jenkins_subnet_Public_eu-north-1a"
  }
}

resource "aws_subnet" "jenkins_subnet_Public_eu-north-1b" {
  vpc_id                                      = aws_vpc.jenkins_vpc.id
  cidr_block                                  = "10.0.2.0/24"
  availability_zone                           = "eu-north-1b"
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = true

  tags = {
    Name = "jenkins_subnet_Public_eu-north-1b"
  }
}

resource "aws_subnet" "jenkins_subnet_Public_eu-north-1c" {
  vpc_id                                      = aws_vpc.jenkins_vpc.id
  cidr_block                                  = "10.0.3.0/24"
  availability_zone                           = "eu-north-1b"
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = true

  tags = {
    Name = "jenkins_subnet_Public_eu-north-1c"
  }
}

##########################
# Create Private Subnets #
##########################

resource "aws_subnet" "jenkins_subnet_Private_eu-north-1a" {
  vpc_id                                      = aws_vpc.jenkins_vpc.id
  cidr_block                                  = "10.0.4.0/24"
  availability_zone                           = "eu-north-1a"
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = true

  tags = {
    Name = "jenkins_subnet_Private_eu-north-1a"
  }
}

resource "aws_subnet" "jenkins_subnet_Private_eu-north-1b" {
  vpc_id                                      = aws_vpc.jenkins_vpc.id
  cidr_block                                  = "10.0.5.0/24"
  availability_zone                           = "eu-north-1b"
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = true

  tags = {
    Name = "jenkins_subnet_Private_eu-north-1b"
  }
}

resource "aws_subnet" "jenkins_subnet_Private_eu-north-1c" {
  vpc_id                                      = aws_vpc.jenkins_vpc.id
  cidr_block                                  = "10.0.6.0/24"
  availability_zone                           = "eu-north-1c"
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch                     = true

  tags = {
    Name = "jenkins_subnet_Private_eu-north-1c"
  }
}

###########################
# Create Internet Gateway #
###########################
resource "aws_internet_gateway" "jenkins_vpc_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = "jenkins_vpc_igw"
  }
}

# 
# Create Route Table for Public Subnets 
# 

resource "aws_route_table" "jenkins_vpc_rt_public" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_vpc_igw.id
  }

  tags = {
    Name = "jenkins_vpc_rt_public"
  }
}

#
# Create Route Table association for Public Subnets 
#

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.jenkins_subnet_Public_eu-north-1a.id
  route_table_id = aws_route_table.jenkins_vpc_rt_public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.jenkins_subnet_Public_eu-north-1b.id
  route_table_id = aws_route_table.jenkins_vpc_rt_public.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.jenkins_subnet_Public_eu-north-1c.id
  route_table_id = aws_route_table.jenkins_vpc_rt_public.id
}

#
# Create SSH Keys
# 

resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.jenkins_key.private_key_pem
  filename = "jenkins_private_key.pem"
  file_permission = "0400"
}

resource "aws_key_pair" "jenkins_public_key" {
  key_name   = "jenkins_public_key"
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

#
# Create Security Group
#

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.jenkins_vpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_sg"
  }
}

#
# Create Jenkins EC2 Instance
#

resource "aws_instance" "jenkins_ec2" {
  ami           = "ami-04cdc91e49cb06165"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.jenkins_subnet_Public_eu-north-1a.id
  key_name      = aws_key_pair.jenkins_public_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = file("install_jenkins.sh")

  tags = {
    Name = "jenkins_ec2"
  }
}
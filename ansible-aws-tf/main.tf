provider "aws" {
  region = "eu-north-1"
}

data "aws_vpc" "default" {
 default = true
}

resource "aws_security_group" "ansible-ec2-sg" {
  name        = "ansible-ec2-ssh-sg"
  description = "SG Ansible EC2"
  vpc_id = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.ingress_ports
    iterator = port
    content {
      from_port = port.value
      to_port   = port.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  
  ingress {
    from_port = "-1"
    to_port = "-1"
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "ansible_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# terraform output -raw private_key > ansible_ssh_key.pem
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.ansible_key.public_key_openssh
}

# Use `local_sensitive_file` for sensitive content
resource "local_sensitive_file" "ansible_key" {
  content             = tls_private_key.ansible_key.private_key_pem
  filename            = "${path.module}/ansible_key.pem"
  file_permission     = "0600"  # Secure permissions for the key
}

resource "aws_instance" "ansible_ec2_nodes" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [aws_security_group.ansible-ec2-sg.id]
  
  for_each = var.ansible_nodes
  tags = {
    Name = each.value
  }
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt update -y
    sudo apt install -y ansible

    hostnamectl set-hostname ${each.value}
  EOF
}

resource "null_resource" "configure_ansible" {

  # This script will run after instances are created to populate the Ansible hosts file
  provisioner "local-exec" {
    command = <<-EOF
      # Add a delay before running the main commands
      sleep 150
      # Provisioning the ansible control node
      ssh -i ${local_sensitive_file.ansible_key.filename} -o StrictHostKeyChecking=no ubuntu@${aws_instance.ansible_ec2_nodes["ansible-control"].public_ip} <<'EOSSH'
      sudo chown -R ubuntu:ubuntu /etc/ansible
      mv /etc/ansible/hosts /etc/ansible/original_hosts
      touch /etc/ansible/hosts
      # Configure ansible.cfg file
      echo "" > /etc/ansible/ansible.cfg
      cat <<ACFG | sudo tee /etc/ansible/ansible.cfg
      [defaults]
      host_key_checking = False
      log_path = /etc/ansible/ansible.log
      ACFG
      cat <<EOL | sudo tee /etc/ansible/hosts
      [web]
      %{ for name, ip in aws_instance.ansible_ec2_nodes }
      %{ if name != "node-03" }
      ${name} ansible_host=${ip.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/etc/ansible/ansible_key.pem
      %{ endif }
      %{ endfor }
      [db]
      node-03 ansible_host=${aws_instance.ansible_ec2_nodes["node-03"].private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/etc/ansible/ansible_key.pem
      EOL
      EOSSH
      # Copy EC2 ssh key to the ansible control node
      scp -i ${local_sensitive_file.ansible_key.filename} -o StrictHostKeyChecking=no ${local_sensitive_file.ansible_key.filename} ubuntu@${aws_instance.ansible_ec2_nodes["ansible-control"].public_ip}:/etc/ansible/ansible_key.pem
      # Do a test ping on all hosts using ansible
      ssh -i ${local_sensitive_file.ansible_key.filename} -o StrictHostKeyChecking=no ubuntu@${aws_instance.ansible_ec2_nodes["ansible-control"].public_ip} <<'EOATST'
      cd /etc/ansible
      ansible -m ping all
      EOATST
    EOF
  }

  depends_on = [aws_instance.ansible_ec2_nodes]
}

output "private_key" {
  value     = tls_private_key.ansible_key.private_key_pem
  sensitive = true
}

output "public_ip" {
  value = toset([for v in aws_instance.ansible_ec2_nodes : "${v.tags["Name"]} - ${v.public_ip} - ${v.public_dns}"])
  description = "Print EC2 instance public IPv4"
}

output "private_ips_with_hostnames" {
  value = {
    for instance in aws_instance.ansible_ec2_nodes :
    instance.tags["Name"] => instance.private_ip
  }
}
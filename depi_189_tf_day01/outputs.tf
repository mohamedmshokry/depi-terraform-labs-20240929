output "instance_public_ip" {
  description = "The public IP address assigned to the instance, if applicable"
  value = aws_instance.depi-web-01.public_ip
}
variable "asg_health_check_type" {
  default = "ELB"
}

variable "asg_ami" {
  default = "ami-0129bfde49ddb0ed6"
}

variable "asg_instance_type" {
  default = "t3.micro"
}

variable "key_name" {
    type = string
    default = "web_ssh_key"
}
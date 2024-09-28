variable "ami" {
  default = "ami-04cdc91e49cb06165"     # Ubuntu Server 24.04 LTS
}

variable "ansible_nodes" {
  type = set(string)
  default = [ "ansible-control", "node-01", "node-02", "node-03"]
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ingress_ports" {
  type = list
  default = [22, 80]
}

variable "key_name" {
    type = string
    default = "ansible_ssh_key"
}
variable "instance_ami" {
  type        = string
  description = "value for ami"
}

variable "instance_type" {
  type        = string
  description = "value for instance type"
  validation {
    condition = contains(["t3.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "Instance type must be one of: t2.micro, t2.small, t2.medium."
  }
}
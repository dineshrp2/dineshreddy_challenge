variable "access_key" {}
variable "secret_key" {}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS instance type"
}

variable "key_name" {
  description = "Name of AWS key pair"
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = "2"
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = "5"
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = "2"
}

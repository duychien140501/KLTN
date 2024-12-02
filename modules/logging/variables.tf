variable "vpc_cidr" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "ubuntu_ami" {
  type = string
}

variable "instance_type" {
  type = string
  default = "t2.medium"
}

variable "logging_subnet_cidrs" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "logging_subnet_id" {
  type = string
}

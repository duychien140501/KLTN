variable "vpc_id" {
  type = string
}

variable "internet_cidr" {
  description = "cidr block for internet"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ubuntu_ami" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "instance_type" {
  type = string
}


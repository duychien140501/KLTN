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

variable "private_ip" {
  type = string
}

variable "database_subnet_ids" {
  type = list(string)
}

variable "bastion_sg_id" {
  type = string
}

variable "backend_subnet_cidrs" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "vpc_cidr" {
  type        = string
}

variable "logging_private_ip" {
  type = string
}

variable "DB_USER" {
  type = string
}

variable "DB_PASS" {
  type = string
}

variable "region" {
  type = string
}

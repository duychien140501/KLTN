variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "frontend_subnet_ids" {
  type = list(string)
}

variable "internet_cidr" {
  description = "cidr block for internet"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_key_name" {
  type = string
}

variable "ubuntu_ami" {
  type = string
}

variable "alb_be_dns" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "frontend_subnet_cidrs" {
  type = list(string)
}

variable "cloudwatch_instance_profile_name" {
  description = "Name of the CloudWatch IAM instance profile"
  type        = string
}

variable "instance_type" {
  type = string
}

variable "logging_private_ip" {
  type = string
}
# Standard Variables
variable "env" {
  type = string
}

variable "aws_region" {
  description = "Region for this infras"
  type        = string
}

variable "private_ip" {
  type = string
}

variable "ubuntu_ami" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR"
  type        = list(string)
}

variable "frontend_subnet_cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
}

variable "backend_subnet_cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
}

variable "logging_subnet_cidrs" {
  description = "Subnet for logstash"
  type        = string
}

variable "instance_type" {
  type = string
}

variable "DB_USER" {
  type = string
}

variable "DB_PASS" {
  type = string
}

variable "image_fe_tier" {
  type = string
}

variable "container_port_fe_tier" {
  type = string
}

variable "image_be_tier" {
  type = string
}

variable "container_port_be_tier" {
  type = string
}

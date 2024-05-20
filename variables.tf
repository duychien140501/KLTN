# Standard Variables
variable "aws-region" {
  description = "Region for this infras"
  type        = string
}

variable "default-name" {
  type = string
}

variable "nat-ami" {
  type = string
}

variable "private-ip" {
  type = string
}

variable "ubuntu-ami" {
  type = string
}

variable "ssh-key-name" {
  type = string
}

variable "vpc-cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public-subnet-cidrs" {
  description = "Public subnet CIDR"
  type        = list(string)
}

variable "frontend-subnet-cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
}

variable "backend-subnet-cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
}

variable "database-subnet-cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
}

variable "default-ssh-port" {
  type = string
}

variable "instance_type" {
  type = string
}

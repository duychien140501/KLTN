variable "vpc-id" {
  type = string
}

variable "internet-cidr" {
  description = "cidr block for internet"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ubuntu-ami" {
  type = string
}

variable "ssh-key-name" {
  type = string
}

variable "private-ip" {
  type = string
}

variable "database-subnet-ids" {
  type = list(string)
}

variable "default-name" {
  type = string
}

variable "nat-sg-id" {
  type = string
}

variable "bastion-sg-id" {
  type = string
}

variable "backend-subnet-cidrs" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

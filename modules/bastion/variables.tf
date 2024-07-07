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

variable "default-name" {
  type = string
}

variable "public-subnet-ids" {
  type = list(string)
}

variable "vpc-cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "instance_type" {
  type = string
}

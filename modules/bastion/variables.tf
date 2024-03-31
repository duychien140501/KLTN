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
  type    = string
  default = "duychien.ng"
}

variable "default-name" {
  type    = string
}

variable "public-subnet-ids" {
  type = list(string)
}

variable "vpc-cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "172.20.0.0/16"
}
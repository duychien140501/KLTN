variable "vpc-id" {
  type = string
}

variable "public-subnet-ids" {
  type = list(string)
}

variable "frontend-subnet-ids" {
  type = list(string)
}

variable "default-name" {
  type    = string
  default = "shopizer"
}

variable "internet-cidr" {
  description = "cidr block for internet"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh-key-name" {
  type    = string
  default = "duychien.ng"
}

variable "ubuntu-ami" {
  type = string
}

variable "default-ssh-port" {
  type    = string
  default = "2222"
}

variable "alb-be-dns" {
  type = string
}

variable "nat-sg-id" {
  type = string
}

variable "bastion-sg-id" {
  type = string
}

variable "frontend-subnet-cidrs" {
  type = list(string)
}

variable "cloudwatch_instance_profile_name" {
  description = "Name of the CloudWatch IAM instance profile"
  type        = string
}

variable "vpc-cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "172.20.0.0/16"
}

variable "public-subnet-cidrs" {
  description = "Public subnet CIDR"
  type        = list(string)
  default     = ["172.20.1.0/24", "172.20.2.0/24"]
}

variable "nat-ami" {
  description = "ami to create nat instance"
  type        = string
}

variable "internet-cidr" {
  description = "cidr block for internet"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh-key-name" {
  type = string
}

variable "frontend-subnet-cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
  default     = ["172.20.3.0/24", "172.20.4.0/24"]

}

variable "backend-subnet-cidrs" {
  description = "Subnet for backend"
  type        = list(string)
  default     = ["172.20.5.0/24", "172.20.6.0/24"]

}

variable "database-subnet-cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
  default     = ["172.20.7.0/24"]
}

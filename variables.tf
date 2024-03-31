# Standard Variables
variable "aws-region" {
  description = "Region for this infras"
  type        = string
  default     = "us-east-1"
}

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

variable "frontend-subnet-cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
  default     = ["172.20.3.0/24", "172.20.4.0/24"]

}

variable "backend-subnet-cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
  default     = ["172.20.5.0/24", "172.20.6.0/24"]

}

variable "database-subnet-cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
  default     = ["172.20.7.0/24"]

}
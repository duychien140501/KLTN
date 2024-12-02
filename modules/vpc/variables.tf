variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR"
  type        = list(string)
}

variable "internet_cidr" {
  description = "cidr block for internet"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_key_name" {
  type = string
}

variable "frontend_subnet_cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
}

variable "backend_subnet_cidrs" {
  description = "Subnet for backend"
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "Subnet for database"
  type        = list(string)
}

variable "logging_subnet_cidrs" {
  description = "Subnet for logging"
  type        = string
}

variable "instance_type" {
  type = string
}

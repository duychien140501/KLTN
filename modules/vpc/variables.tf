variable "vpc-cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public-subnet-cidrs" {
  description = "Public subnet CIDR"
  type        = list(string)
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
}

variable "backend-subnet-cidrs" {
  description = "Subnet for backend"
  type        = list(string)
}

variable "database-subnet-cidrs" {
  description = "Subnet for frontend"
  type        = list(string)
}

variable "logstash-subnet-cidrs" {
  description = "Subnet for logstash"
  type        = string
}

variable "elasticsearch-subnet-cidrs" {
  description = "Subnet for elasticsearch"
  type        = string
}

variable "kibana-subnet-cidrs" {
  description = "Subnet for kibana"
  type        = string
}

variable "instance_type" {
  type = string
}

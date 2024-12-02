variable "frontend_instance_ids" {
  type = list(string)
}

variable "backend_instance_ids" {
  type = list(string)
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

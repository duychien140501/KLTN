output "vpc-id" {
  value = aws_vpc.shopzer-vpc.id
}

output "public-subnet-ids" {
  value = [for subnet in aws_subnet.public_subnet : subnet.id]
}

output "frontend-subnet-ids" {
  value = [for subnet in aws_subnet.frontend_subnet : subnet.id]
}

output "backend-subnet-ids" {
  value = [for subnet in aws_subnet.backend_subnet : subnet.id]
}

output "database-subnet-ids" {
  value = [for subnet in aws_subnet.database_subnet : subnet.id]
}

output "logstash-subnet-id" {
  value = aws_subnet.logstash_subnet.id
}

output "elasticsearch-subnet-id" {
  value = aws_subnet.elasticsearch_subnet.id
}

output "kibana-subnet-id" {
  value = aws_subnet.kibana_subnet.id
}


output "backend-subnet-cidrs" {
  value = var.backend-subnet-cidrs
}

output "frontend-subnet-cidrs" {
  value = var.frontend-subnet-cidrs
}

output "logstash-subnet-cidrs" {
  value = var.logstash-subnet-cidrs
}

output "elasticsearch-subnet-cidrs" {
  value = var.elasticsearch-subnet-cidrs
}

output "kibana-subnet-cidrs" {
  value = var.kibana-subnet-cidrs
}
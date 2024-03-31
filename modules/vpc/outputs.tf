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

output "nat-sg-id" {
  value = aws_security_group.nat-sg.id
}

output "backend-subnet-cidrs" {
  value = var.backend-subnet-cidrs
}

output "frontend-subnet-cidrs" {
  value = var.frontend-subnet-cidrs
}

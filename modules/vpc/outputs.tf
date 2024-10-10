output "vpc_id" {
  value = aws_vpc.shopzer_vpc.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public_subnet : subnet.id]
}

output "frontend_subnet_ids" {
  value = [for subnet in aws_subnet.frontend_subnet : subnet.id]
}

output "backend_subnet_ids" {
  value = [for subnet in aws_subnet.backend_subnet : subnet.id]
}

output "database_subnet_ids" {
  value = [for subnet in aws_subnet.database_subnet : subnet.id]
}

output "logging_subnet_id" {
  value = aws_subnet.logging_subnet.id
}

output "backend_subnet_cidrs" {
  value = var.backend_subnet_cidrs
}

output "frontend_subnet_cidrs" {
  value = var.frontend_subnet_cidrs
}

output "logging_subnet_cidrs" {
  value = var.logging_subnet_cidrs
}
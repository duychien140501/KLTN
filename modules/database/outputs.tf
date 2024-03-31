output "database-ip" {
  value = var.private-ip
}

output "database-sg-id" {
  value = aws_security_group.database-sg.id
}
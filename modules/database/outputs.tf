output "database_ip" {
  value = var.private_ip
}

output "database_sg_id" {
  value = aws_security_group.database_sg.id
}

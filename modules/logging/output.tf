output "logging_instance" {
  value = aws_instance.logging_instance
}

output "logging_private_ip" {
  value = aws_instance.logging_instance.private_ip
}

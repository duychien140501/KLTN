output "be-alb-id" {
  value = aws_lb.be-alb.id
}

output "be-dns-name" {
  value = aws_lb.be-alb.dns_name
}

output "be-alb-arn" {
  value = aws_lb.be-alb.arn
}

output "be-alb-sg-id" {
  value = aws_security_group.be-alb-sg.id
}

output "backend_instance_ids" {
  value       = aws_instance.backend.*.id
  description = "List of IDs of the backend instances"
}

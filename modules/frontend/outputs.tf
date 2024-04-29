output "fe-alb-dns" {
  value = aws_lb.fe-alb.dns_name
}

output "frontend_instance_ids" {
  value       = aws_instance.frontend.*.id
  description = "List of IDs of the frontend instances"
}

output "admin_instance_ids" {
  value       = aws_instance.admin.*.id
  description = "List of IDs of the admin instances"
}

output "fe-alb-arn" {
  value = aws_lb.fe-alb.arn
}

output "fe-alb-id" {
  value = aws_lb.fe-alb.id
}

output "fe-alb-sg-id" {
  value = aws_security_group.fe-alb-sg.id
}
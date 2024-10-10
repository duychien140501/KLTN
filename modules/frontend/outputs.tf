output "fe_alb_dns" {
  value = aws_lb.fe_alb.dns_name
}

output "frontend_instance_ids" {
  value       = aws_instance.frontend.*.id
  description = "List of IDs of the frontend instances"
}

output "admin_instance_ids" {
  value       = aws_instance.admin.*.id
  description = "List of IDs of the admin instances"
}

output "fe_alb_arn" {
  value = aws_lb.fe_alb.arn
}

output "fe_alb_id" {
  value = aws_lb.fe_alb.id
}

output "fe_alb_sg_id" {
  value = aws_security_group.fe_alb_sg.id
}

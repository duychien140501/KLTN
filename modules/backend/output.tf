output "be_alb_id" {
  value = aws_lb.be_alb.id
}

output "be_dns_name" {
  value = aws_lb.be_alb.dns_name
}

output "be_alb_arn" {
  value = aws_lb.be_alb.arn
}

output "be_alb_sg_id" {
  value = aws_security_group.be_alb_sg.id
}

output "backend_instance_ids" {
  value       = aws_instance.backend.*.id
  description = "List of IDs of the backend instances"
}

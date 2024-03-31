output "cloudwatch_role_arn" {
  value = aws_iam_role.cloudwatch_role.arn
}

output "cloudwatch_instance_profile_name" {
  value = aws_iam_instance_profile.cloudwatch_instance_profile.name
}

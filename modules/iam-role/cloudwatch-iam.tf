resource "aws_iam_role" "cloudwatch_role" {
  name = "CloudWatchAgentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.cloudwatch_role.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_admin_attach" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
  role       = aws_iam_role.cloudwatch_role.name
}

resource "aws_iam_instance_profile" "cloudwatch_instance_profile" {
  name = "CloudWatchAgentProfile"
  role = aws_iam_role.cloudwatch_role.name
}

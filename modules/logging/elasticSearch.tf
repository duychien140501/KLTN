# # Create a security group for Elasticsearch
# resource "aws_security_group" "elasticsearch_sg" {
#     name        = "elasticsearch-sg"
#     description = "Security group for Elasticsearch"

#     ingress =[
#         {
#             description      = "Allow to https"
#             from_port   = 9200
#             to_port     = 9200
#             protocol    = "tcp"
#             cidr_blocks = ["0.0.0.0/0"]
#             ipv6_cidr_blocks = []
#             prefix_list_ids  = []
#             security_groups = []
#             self             = false
#         },
#         {
#             description      = "Allow to https"
#             from_port   = 9300
#             to_port     = 9300
#             protocol    = "tcp"
#             cidr_blocks = ["0.0.0.0/0"]
#             ipv6_cidr_blocks = []
#             prefix_list_ids  = []
#             security_groups = []
#             self             = false
#         },
#         {
#         description      = "Allow Bastion SSH"
#         from_port        = 2222
#         to_port          = 2222
#         protocol         = "tcp"
#         cidr_blocks = []
#         ipv6_cidr_blocks = []
#         prefix_list_ids  = []
#         security_groups  = ["0.0.0.0/0"]
#         self             = false
#         }
#     ]

#     tags = {
#       Name = "Elasticsearch Security Group"
#     }
# }

# # Create an EC2 instance for Elasticsearch
# resource "aws_instance" "elasticsearch_instance" {
#     ami           = var.nat-ami  # Replace with the desired AMI ID
#     instance_type = var.instance_type  # Replace with the desired instance type
#     key_name      = var.ssh-key-name
#     subnet_id     = var.elasticsearch-subnet-cidrs
#     vpc_security_group_ids = [aws_security_group.elasticsearch_sg.id]

#     user_data = file("${path.module}/elasticsearch.sh")
#     tags = {
#         Name = "elasticsearch-instance"
#     }
# }
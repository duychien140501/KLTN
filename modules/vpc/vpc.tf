resource "aws_vpc" "shopzer-vpc" {
  cidr_block = var.vpc-cidr
  tags = {
    Name        = "Shopizer VPC",
    Description = "Shopizer VPC"
  }
}

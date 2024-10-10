resource "aws_vpc" "shopzer_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "Shopizer VPC",
    Description = "Shopizer VPC"
  }
}

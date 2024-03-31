resource "aws_vpc" "shopzer-vpc" {
  cidr_block = var.vpc-cidr
  tags = {
    Name        = "Shopizer VPC created by terraform",
    Description = "VPC for creating Shopizer infrastructure resourece"
  }
}

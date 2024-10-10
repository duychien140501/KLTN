# IGW
resource "aws_internet_gateway" "main_igw" {

  vpc_id = aws_vpc.shopzer_vpc.id
  tags = {
    Name        = "Shopizer IGW"
    Description = "IGW created by terraform"
  }

  depends_on = [aws_vpc.shopzer_vpc]
}

resource "aws_eip" "nat_eip" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name = "nat_eip ${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = length(var.public_subnet_cidrs)
  subnet_id     = aws_subnet.public_subnet[count.index].id
  allocation_id = aws_eip.nat_eip[count.index].id

  tags = {
    Name        = "nat_gateway ${count.index + 1}"
    Description = "nat gateway for shopizer"
  }
}

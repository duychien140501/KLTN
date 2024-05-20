# IGW
resource "aws_internet_gateway" "main-igw" {

  vpc_id = aws_vpc.shopzer-vpc.id
  tags = {
    Name        = "Shopizer IGW"
    Description = "IGW created by terraform"
  }

  depends_on = [aws_vpc.shopzer-vpc]
}

# Network interface
resource "aws_network_interface" "network_interface" {
  count             = length(var.public-subnet-cidrs)
  subnet_id         = aws_subnet.public_subnet[count.index].id
  security_groups   = [aws_security_group.nat-sg.id]
  source_dest_check = false

  tags = {
    Name        = "nat_instance_network_interface ${count.index + 1}"
    Description = "network interface to create nat instance"
  }

  depends_on = [aws_subnet.public_subnet, aws_security_group.nat-sg]
}

# NAT instance
resource "aws_instance" "nat_instance" {
  count         = length(var.public-subnet-cidrs)
  ami           = var.nat-ami
  instance_type = var.instance_type
  key_name      = var.ssh-key-name
  network_interface {
    network_interface_id = aws_network_interface.network_interface[count.index].id
    device_index         = 0
  }

  tags = {
    Name        = "NAT instance ${count.index + 1}"
    Description = ""
  }

  depends_on = [aws_network_interface.network_interface]

}

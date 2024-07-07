aws-region            = "us-east-1"
vpc-cidr              = "172.20.0.0/16"
public-subnet-cidrs   = ["172.20.1.0/24", "172.20.2.0/24"]
frontend-subnet-cidrs = ["172.20.3.0/24", "172.20.4.0/24"]
backend-subnet-cidrs  = ["172.20.5.0/24", "172.20.6.0/24"]
database-subnet-cidrs = ["172.20.7.0/24"]
default-name          = "shopizer"
nat-ami               = "ami-04106ae1c90766385"
ubuntu-ami            = "ami-0fc5d935ebf8bc3bc"
instance_type         = "t2.micro"
private-ip            = "172.20.7.47"
ssh-key-name          = "duychien.ng"
default-ssh-port      = "2222"
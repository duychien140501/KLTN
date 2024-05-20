provider "aws" {
  region = var.aws-region
}

# VPC module
module "vpc" {
  source                = "./modules/vpc"
  vpc-cidr              = var.vpc-cidr
  public-subnet-cidrs   = var.public-subnet-cidrs
  frontend-subnet-cidrs = var.frontend-subnet-cidrs
  backend-subnet-cidrs  = var.backend-subnet-cidrs
  database-subnet-cidrs = var.database-subnet-cidrs
  ssh-key-name          = var.ssh-key-name
  nat-ami               = var.nat-ami
  instance_type         = var.instance_type
}

# Bastion module
module "bastion" {
  source            = "./modules/bastion"
  default-name      = var.default-name
  vpc-id            = module.vpc.vpc-id
  public-subnet-ids = module.vpc.public-subnet-ids
  ubuntu-ami        = var.ubuntu-ami
  ssh-key-name      = var.ssh-key-name
  vpc-cidr          = var.vpc-cidr
  instance_type     = var.instance_type

  depends_on = [module.vpc]
}

# cloudwatch-iam-role
module "cloudwatch_iam" {
  source = "./modules/iam-role"
}

# Database module
module "database" {
  source               = "./modules/database"
  vpc-id               = module.vpc.vpc-id
  private-ip           = var.private-ip
  database-subnet-ids  = module.vpc.database-subnet-ids
  ubuntu-ami           = var.ubuntu-ami
  instance_type        = var.instance_type
  ssh-key-name         = var.ssh-key-name
  default-name         = var.default-name
  nat-sg-id            = module.vpc.nat-sg-id
  bastion-sg-id        = module.bastion.bastion-sg-id
  backend-subnet-cidrs = module.vpc.backend-subnet-cidrs

  depends_on = [module.vpc, module.bastion]
}

# Backend module
module "backend" {
  source                           = "./modules/backend"
  vpc-id                           = module.vpc.vpc-id
  public-subnet-ids                = module.vpc.public-subnet-ids
  backend-subnet-ids               = module.vpc.backend-subnet-ids
  ubuntu-ami                       = var.ubuntu-ami
  instance_type                    = var.instance_type
  ssh-key-name                     = var.ssh-key-name
  default-ssh-port                 = var.default-ssh-port
  default-name                     = var.default-name
  nat-sg-id                        = module.vpc.nat-sg-id
  bastion-sg-id                    = module.bastion.bastion-sg-id
  database-sg-id                   = module.database.database-sg-id
  backend-subnet-cidrs             = module.vpc.backend-subnet-cidrs
  cloudwatch_instance_profile_name = module.cloudwatch_iam.cloudwatch_instance_profile_name

  depends_on = [module.vpc, module.bastion, module.database, module.cloudwatch_iam]

}

# Frontend module
module "frontend" {
  source                           = "./modules/frontend"
  vpc-id                           = module.vpc.vpc-id
  public-subnet-ids                = module.vpc.public-subnet-ids
  frontend-subnet-ids              = module.vpc.frontend-subnet-ids
  alb-be-dns                       = module.backend.be-dns-name
  ubuntu-ami                       = var.ubuntu-ami
  instance_type                    = var.instance_type
  default-name                     = var.default-name
  nat-sg-id                        = module.vpc.nat-sg-id
  bastion-sg-id                    = module.bastion.bastion-sg-id
  frontend-subnet-cidrs            = module.vpc.frontend-subnet-cidrs
  cloudwatch_instance_profile_name = module.cloudwatch_iam.cloudwatch_instance_profile_name
  ssh-key-name                     = var.ssh-key-name
  default-ssh-port                 = var.default-ssh-port
  depends_on                       = [module.vpc, module.bastion, module.backend, module.cloudwatch_iam]
}

module "cloudwatch" {
  source                = "./modules/cloudwatch"
  frontend_instance_ids = module.frontend.frontend_instance_ids
  admin_instance_ids    = module.frontend.admin_instance_ids
  backend_instance_ids  = module.backend.backend_instance_ids

  depends_on = [module.frontend, module.backend]
}

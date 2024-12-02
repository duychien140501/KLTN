provider "aws" {
  region     = var.aws_region
}

# VPC module
module "vpc" {
  source                = "./modules/vpc"
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  frontend_subnet_cidrs = var.frontend_subnet_cidrs
  backend_subnet_cidrs  = var.backend_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  logging_subnet_cidrs  = var.logging_subnet_cidrs
  ssh_key_name          = var.ssh_key_name
  instance_type         = var.instance_type
}

# Waf module
module "waf" {
  source     = "./modules/waf"
  fe_alb_arn = module.frontend.fe_alb_arn
}

# Logging module
module "logging" {
  source               = "./modules/logging"
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = var.vpc_cidr
  logging_subnet_cidrs = var.logging_subnet_cidrs
  bastion_sg_id        = module.bastion.bastion_sg_id
  ssh_key_name         = var.ssh_key_name
  ubuntu_ami           = var.ubuntu_ami
  logging_subnet_id    = module.vpc.logging_subnet_id
}

# Bastion module
module "bastion" {
  source            = "./modules/bastion"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  ubuntu_ami        = var.ubuntu_ami
  ssh_key_name      = var.ssh_key_name
  vpc_cidr          = var.vpc_cidr
  instance_type     = var.instance_type

  depends_on = [module.vpc]
}

# cloudwatch_iam_role
module "cloudwatch_iam" {
  source = "./modules/iam-role"
}

# Database module
module "database" {
  source               = "./modules/database"
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = var.vpc_cidr
  private_ip           = var.private_ip
  database_subnet_ids  = module.vpc.database_subnet_ids
  ubuntu_ami           = var.ubuntu_ami
  instance_type        = var.instance_type
  ssh_key_name         = var.ssh_key_name
  bastion_sg_id        = module.bastion.bastion_sg_id
  backend_subnet_cidrs = module.vpc.backend_subnet_cidrs
  logging_private_ip   = module.logging.logging_private_ip
  DB_USER              = var.DB_USER
  DB_PASS              = var.DB_PASS

  depends_on = [module.vpc, module.bastion]
}

# Backend module
module "backend" {
  source                           = "./modules/backend"
  vpc_id                           = module.vpc.vpc_id
  vpc_cidr                         = var.vpc_cidr
  public_subnet_ids                = module.vpc.public_subnet_ids
  backend_subnet_ids               = module.vpc.backend_subnet_ids
  ubuntu_ami                       = var.ubuntu_ami
  instance_type                    = var.instance_type
  ssh_key_name                     = var.ssh_key_name
  bastion_sg_id                    = module.bastion.bastion_sg_id
  database_sg_id                   = module.database.database_sg_id
  backend_subnet_cidrs             = module.vpc.backend_subnet_cidrs
  cloudwatch_instance_profile_name = module.cloudwatch_iam.cloudwatch_instance_profile_name
  logging_private_ip               = module.logging.logging_private_ip
  image_be_tier                    = var.image_be_tier
  container_port_be_tier           = var.container_port_be_tier

  depends_on = [module.vpc, module.bastion, module.database, module.cloudwatch_iam]

}

# Frontend module
module "frontend" {
  source                           = "./modules/frontend"
  vpc_id                           = module.vpc.vpc_id
  vpc_cidr                         = var.vpc_cidr
  public_subnet_ids                = module.vpc.public_subnet_ids
  frontend_subnet_ids              = module.vpc.frontend_subnet_ids
  alb_be_dns                       = module.backend.be_dns_name
  ubuntu_ami                       = var.ubuntu_ami
  instance_type                    = var.instance_type
  bastion_sg_id                    = module.bastion.bastion_sg_id
  frontend_subnet_cidrs            = module.vpc.frontend_subnet_cidrs
  cloudwatch_instance_profile_name = module.cloudwatch_iam.cloudwatch_instance_profile_name
  ssh_key_name                     = var.ssh_key_name
  image_fe_tier                    = var.image_fe_tier
  container_port_fe_tier           = var.container_port_fe_tier
  logging_private_ip               = module.logging.logging_private_ip

  depends_on = [module.vpc, module.bastion, module.backend, module.cloudwatch_iam]
}

module "monitoring" {
  source                = "./modules/monitoring"
  frontend_instance_ids = module.frontend.frontend_instance_ids
  backend_instance_ids  = module.backend.backend_instance_ids

  depends_on = [module.frontend, module.backend]
}

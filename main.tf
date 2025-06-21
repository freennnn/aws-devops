# Multi-AZ Kubernetes-ready infrastructure

# Networking module
module "networking" {
  source = "./modules/networking"

  project_name          = var.project_name
  aws_region            = var.aws_region
  vpc_cidr              = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  availability_zone_1   = var.availability_zone_1
  availability_zone_2   = var.availability_zone_2
  ssh_cidr_blocks       = var.ssh_cidr_blocks
  enable_nat_gateway    = var.enable_nat_gateway
}

# Bastion Host module
module "bastion" {
  source = "./modules/bastion"

  project_name      = var.project_name
  instance_type     = var.bastion_instance_type
  key_name          = var.key_name
  public_subnet_id  = module.networking.public_subnet_1_id
  security_group_id = module.networking.bastion_security_group_id
  enable_eip        = var.enable_bastion_eip
}

# Storage module
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  bucket_name  = var.app_bucket_name
}

# Compute module (can be deployed in private subnets)
module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  instance_type     = var.instance_type
  key_name          = var.key_name
  subnet_id         = var.deploy_to_private ? module.networking.private_subnet_1_id : module.networking.public_subnet_1_id
  security_group_id = var.deploy_to_private ? module.networking.private_security_group_id : module.networking.web_security_group_id
  s3_bucket_arn     = module.storage.bucket_arn
}


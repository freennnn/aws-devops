# Free Tier friendly: 1 t2.micro EC2 instance + S3 bucket

# Networking module
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  ssh_cidr_blocks    = var.ssh_cidr_blocks
}

# Storage module
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  bucket_name  = var.app_bucket_name
}

# Compute module (Free Tier: single t2.micro instance)
module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  instance_type     = var.instance_type
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.networking.security_group_id
  s3_bucket_arn     = module.storage.bucket_arn
}

# VPC Infrastructure outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

# Public Subnet outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "public_subnet_1_id" {
  description = "ID of the first public subnet"
  value       = module.networking.public_subnet_1_id
}

output "public_subnet_2_id" {
  description = "ID of the second public subnet"
  value       = module.networking.public_subnet_2_id
}

# Private Subnet outputs
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "private_subnet_1_id" {
  description = "ID of the first private subnet"
  value       = module.networking.private_subnet_1_id
}

output "private_subnet_2_id" {
  description = "ID of the second private subnet"
  value       = module.networking.private_subnet_2_id
}

# Security Group outputs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.networking.web_security_group_id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = module.networking.bastion_security_group_id
}

output "private_security_group_id" {
  description = "ID of the private security group"
  value       = module.networking.private_security_group_id
}

# Bastion Host outputs
output "bastion_instance_id" {
  description = "ID of the bastion host instance"
  value       = module.bastion.bastion_instance_id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "bastion_eip" {
  description = "Elastic IP address of the bastion host (if enabled)"
  value       = module.bastion.bastion_eip
}

# Application Instance outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.compute.instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.compute.instance_private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.compute.instance_public_dns
}

# Storage outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.storage.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.storage.bucket_arn
}

# NAT Gateway outputs
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.networking.nat_gateway_ids
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.networking.availability_zones
}

# Connection Information
output "ssh_connection_bastion" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.bastion.bastion_public_ip}"
}

output "ssh_connection_private_via_bastion" {
  description = "SSH command to connect to private instance via bastion (if deployed to private)"
  value       = var.deploy_to_private ? "ssh -i ~/.ssh/${var.key_name}.pem -J ec2-user@${module.bastion.bastion_public_ip} ec2-user@${module.compute.instance_private_ip}" : "Direct SSH to public instance"
}

# Kubernetes cluster outputs
output "k3s_master_instance_id" {
  description = "ID of the K3s master instance"
  value       = module.kubernetes.k3s_master_instance_id
}

output "k3s_master_private_ip" {
  description = "Private IP address of the K3s master"
  value       = module.kubernetes.k3s_master_private_ip
}

output "k3s_worker_instance_id" {
  description = "ID of the K3s worker instance"
  value       = module.kubernetes.k3s_worker_instance_id
}

output "k3s_worker_private_ip" {
  description = "Private IP address of the K3s worker"
  value       = module.kubernetes.k3s_worker_private_ip
}

output "k3s_cluster_endpoint" {
  description = "K3s cluster API endpoint"
  value       = module.kubernetes.k3s_cluster_endpoint
}

# Connection commands for K8s management
output "ssh_connection_k3s_master" {
  description = "SSH command to connect to K3s master node via bastion"
  value       = var.deploy_k3s_to_private ? "ssh -i ~/.ssh/${var.key_name}.pem -J ec2-user@${module.bastion.bastion_public_ip} ubuntu@${module.kubernetes.k3s_master_private_ip}" : "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.kubernetes.k3s_master_private_ip}"
}

output "ssh_connection_k3s_worker" {
  description = "SSH command to connect to K3s worker node via bastion"
  value       = var.deploy_k3s_to_private ? "ssh -i ~/.ssh/${var.key_name}.pem -J ec2-user@${module.bastion.bastion_public_ip} ubuntu@${module.kubernetes.k3s_worker_private_ip}" : "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.kubernetes.k3s_worker_private_ip}"
}

output "kubectl_setup_command" {
  description = "Command to setup kubectl on bastion host"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.bastion.bastion_public_ip} './setup-kubeconfig.sh ${module.kubernetes.k3s_master_private_ip} ~/.ssh/${var.key_name}.pem'"
}



# Infrastructure outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.networking.public_subnet_id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.networking.security_group_id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.compute.instance_public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.compute.instance_public_dns
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.storage.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.storage.bucket_arn
}

 
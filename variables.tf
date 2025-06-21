# Project configuration
variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "rs-aws-devops"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-north-1"
}

# Networking configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for first public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for second public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for first private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for second private subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "availability_zone_1" {
  description = "First availability zone"
  type        = string
  default     = "eu-north-1a"
}

variable "availability_zone_2" {
  description = "Second availability zone"
  type        = string
  default     = "eu-north-1b"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (true for NAT Gateway, false for cheaper NAT instance)"
  type        = bool
  default     = true
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access (replace with your IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Change this to your IP for security
}

# EC2 configuration
variable "instance_type" {
  description = "EC2 instance type for main applications"
  type        = string
  default     = "t3.micro" # Free Tier eligible
}

variable "bastion_instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t3.micro" # Free Tier eligible
}

variable "key_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
  default     = "rs-devops-key"
}

variable "enable_bastion_eip" {
  description = "Enable Elastic IP for bastion host"
  type        = bool
  default     = true
}

variable "deploy_to_private" {
  description = "Deploy application instances to private subnets (requires bastion for access)"
  type        = bool
  default     = false # Set to true for production-like setup
}

# S3 configuration
variable "app_bucket_name" {
  description = "Name for the application S3 bucket (must be globally unique)"
  type        = string
  default     = "rs-aws-devops-app-bucket-freen"
}

# Environment configuration
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

# GitHub Actions configuration
variable "github_repository" {
  description = "GitHub repository in format 'username/repository-name'"
  type        = string
  default     = "freennnn/aws-devops" # Update this to match your GitHub repo
}




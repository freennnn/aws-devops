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

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access (replace with your IP)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Change this to your IP for security
}

# EC2 configuration (Free Tier)
variable "instance_type" {
  description = "EC2 instance type (Free Tier: t2.micro)"
  type        = string
  default     = "t3.micro" # Free Tier eligible
}

variable "key_name" {
  description = "Name of the AWS key pair for SSH access (optional)"
  type        = string
  default     = "rs-devops-key"
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
  default     = "freen/rs-aws-devops" # Update this to match your GitHub repo
}



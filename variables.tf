variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "my-terraform-demo-bucket-2024"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
} 
variable "project_name" {
  description = "Name of the project"
  type        = string
}



variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "ID of the subnet where the EC2 instance will be launched"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group for the EC2 instance"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for application data"
  type        = string
}
 

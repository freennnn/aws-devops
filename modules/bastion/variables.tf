variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet where bastion will be deployed"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group for bastion host"
  type        = string
}

variable "enable_eip" {
  description = "Whether to create an Elastic IP for the bastion host"
  type        = bool
  default     = true
} 

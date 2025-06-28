variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
}

variable "master_instance_type" {
  description = "EC2 instance type for K3s master node"
  type        = string
  default     = "t3.micro" # Free Tier eligible
}

variable "worker_instance_type" {
  description = "EC2 instance type for K3s worker node"
  type        = string
  default     = "t3.micro" # Free Tier eligible
}

variable "key_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
}

variable "master_subnet_id" {
  description = "Subnet ID where to deploy the K3s master node"
  type        = string
}

variable "worker_subnet_id" {
  description = "Subnet ID where to deploy the K3s worker node"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the K3s cluster nodes"
  type        = string
}

variable "k3s_token" {
  description = "Token for K3s cluster authentication"
  type        = string
  default     = "k3s-cluster-secret-token-12345"
  sensitive   = true
}

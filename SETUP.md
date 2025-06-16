# AWS DevOps Infrastructure Setup

This repository contains Terraform configuration for a complete AWS DevOps infrastructure.

## 🚀 Quick Start

### 1. Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0.0 installed
- An AWS key pair (optional, for SSH access)

### 2. Configuration
```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

### 3. Required Changes in terraform.tfvars
- `ssh_cidr_blocks`: Replace with your IP address
- `app_bucket_name`: Make it globally unique (add your name)
- `key_name`: Your AWS key pair name (optional)
- `aws_region`: Your preferred AWS region

### 4. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy
terraform apply
```

## 🔒 Security Notes

- Never commit `terraform.tfvars` to Git
- State files contain sensitive data - use remote state for teams
- Restrict SSH access to your IP only
- Review security group rules before deployment

## 🏗️ Infrastructure Components

- **VPC**: Isolated network environment
- **EC2**: t3.micro instance with Node.js 22 + Caddy
- **S3**: Application data storage
- **IAM**: Roles and policies for EC2-S3 access
- **Security Groups**: Network access control

## 💰 Cost Estimate

Most resources are Free Tier eligible:
- EC2 t3.micro: 750 hours/month free
- S3: 5GB storage free
- EBS: 30GB free
- Estimated cost: $0-2/month

## 🆘 Troubleshooting

### Common Issues
1. **Bucket name conflicts**: Make bucket name more unique
2. **Permission errors**: Check AWS IAM permissions
3. **Instance launch failures**: Try different instance type or region

### Getting Help
- Check AWS CloudFormation events for detailed errors
- Review Terraform logs: `TF_LOG=DEBUG terraform apply`
- Ensure your AWS credentials have sufficient permissions 
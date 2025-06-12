# Basic AWS Terraform Setup

This is a basic Terraform setup that creates:
- An EC2 instance (t2.micro)
- An S3 bucket with versioning enabled

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed
- AWS account with appropriate permissions

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Review the planned changes:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

4. When you're done, destroy the resources:
```bash
terraform destroy
```

## Configuration

You can modify the following variables in `variables.tf`:
- `aws_region`: AWS region to deploy resources (default: us-east-1)
- `instance_type`: EC2 instance type (default: t2.micro)
- `bucket_name`: Name of the S3 bucket
- `environment`: Environment name (default: dev)

## Outputs

After applying, Terraform will output:
- S3 bucket name and ARN
- EC2 instance ID and public IP
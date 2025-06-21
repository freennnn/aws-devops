# AWS DevOps Infrastructure - Task 2: Basic Kubernetes Networking Configuration

This repository contains Terraform code for creating a production-ready, multi-AZ networking infrastructure suitable for Kubernetes clusters on AWS.

## 🏗️ Architecture Overview

### Network Architecture
```
Internet
    │
    ├── Internet Gateway
    │
    ├── Public Subnets (Multi-AZ)
    │   ├── AZ1: 10.0.1.0/24
    │   ├── AZ2: 10.0.2.0/24
    │   ├── Bastion Host (AZ1)
    │   └── NAT Gateways
    │
    └── Private Subnets (Multi-AZ)
        ├── AZ1: 10.0.3.0/24
        ├── AZ2: 10.0.4.0/24
        └── Application Instances
```

### Key Components

#### 🌐 **VPC (Virtual Private Cloud)**
- **CIDR Block**: `10.0.0.0/16` (65,536 IP addresses)
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled
- **Multi-AZ**: Spans across 2 availability zones

#### 🔗 **Subnets**
- **Public Subnets**: 2 subnets across different AZs
  - `10.0.1.0/24` (AZ1) - 256 IPs
  - `10.0.2.0/24` (AZ2) - 256 IPs
  - Auto-assign public IPs enabled
- **Private Subnets**: 2 subnets across different AZs
  - `10.0.3.0/24` (AZ1) - 256 IPs
  - `10.0.4.0/24` (AZ2) - 256 IPs
  - No direct internet access

#### 🚪 **Internet Gateway**
- Provides internet access to public subnets
- Attached to VPC for bidirectional internet connectivity

#### 🔄 **NAT Gateways**
- **High Availability**: One NAT Gateway per AZ
- **Purpose**: Allows private subnet instances to access internet
- **Elastic IPs**: Dedicated static IPs for each NAT Gateway

#### 🛡️ **Security Groups**

1. **Web Security Group** (`web-sg`)
   - HTTP (80) from anywhere
   - HTTPS (443) from anywhere
   - SSH (22) from bastion only

2. **Bastion Security Group** (`bastion-sg`)
   - SSH (22) from specified CIDR blocks
   - All outbound traffic allowed

3. **Private Security Group** (`private-sg`)
   - SSH (22) from bastion only
   - HTTP/HTTPS from web tier
   - Application ports (3000, 3001) from web tier
   - All VPC traffic allowed

4. **Database Security Group** (`database-sg`)
   - MySQL (3306) from application tiers
   - PostgreSQL (5432) from application tiers

#### 🏰 **Bastion Host**
- **Purpose**: Secure jump server for private subnet access
- **Location**: Public subnet in AZ1
- **Instance Type**: `t3.micro` (Free Tier eligible)
- **Features**:
  - AWS CLI v2 pre-installed
  - Session Manager plugin
  - Enhanced SSH security
  - CloudWatch agent ready

#### 🛣️ **Route Tables**
- **Public Route Table**: Routes to Internet Gateway (0.0.0.0/0)
- **Private Route Tables**: Routes to respective NAT Gateways

## 📁 Project Structure

```
├── modules/
│   ├── networking/
│   │   ├── main.tf              # VPC, subnets, IGW, NAT
│   │   ├── security_groups.tf   # Security group definitions
│   │   ├── variables.tf         # Input variables
│   │   └── outputs.tf           # Output values
│   ├── bastion/
│   │   ├── main.tf              # Bastion host instance
│   │   ├── variables.tf         # Input variables
│   │   ├── outputs.tf           # Output values
│   │   └── user_data.sh         # Startup script
│   ├── compute/
│   │   └── ...                  # Application instances
│   └── storage/
│       └── ...                  # S3 bucket configuration
├── main.tf                      # Main Terraform configuration
├── variables.tf                 # Global variables
├── outputs.tf                   # Global outputs
├── provider.tf                  # AWS provider configuration
├── backend.tf                   # Remote state configuration
└── README.md                    # This file
```

## 🚀 Getting Started

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **SSH Key Pair** created in AWS EC2

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd aws-devops
   ```

2. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```

## ⚙️ Configuration Options

### Key Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `project_name` | Project name for resource naming | `rs-aws-devops` | No |
| `aws_region` | AWS region for deployment | `eu-north-1` | No |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` | No |
| `availability_zone_1` | First AZ | `eu-north-1a` | No |
| `availability_zone_2` | Second AZ | `eu-north-1b` | No |
| `enable_nat_gateway` | Enable NAT Gateway (vs NAT instance) | `true` | No |
| `key_name` | AWS key pair name | `rs-devops-key` | Yes |
| `deploy_to_private` | Deploy apps to private subnets | `false` | No |

### Example terraform.tfvars

```hcl
project_name = "my-k8s-infrastructure"
aws_region = "us-west-2"
availability_zone_1 = "us-west-2a"
availability_zone_2 = "us-west-2b"
key_name = "my-key-pair"
enable_nat_gateway = true
deploy_to_private = true
ssh_cidr_blocks = ["1.2.3.4/32"]  # Your IP address
```

## 🔐 Security Best Practices

### Network Security
- **Private Subnets**: Application instances have no direct internet access
- **Bastion Host**: Single point of entry for private resources
- **Security Groups**: Least privilege access rules
- **SSH Keys**: Key-based authentication only

### Access Patterns
1. **Public Access**: Internet → Load Balancer → Public Subnet
2. **Private Access**: SSH → Bastion → Private Subnet
3. **Outbound**: Private Subnet → NAT Gateway → Internet

## 🔧 Usage Examples

### SSH Access

**Connect to Bastion Host:**
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-public-ip>
```

**Connect to Private Instance via Bastion:**
```bash
ssh -i ~/.ssh/your-key.pem -J ec2-user@<bastion-ip> ec2-user@<private-ip>
```

### Resource Information

After deployment, Terraform outputs provide:
- VPC and subnet IDs
- Security group IDs
- Bastion host connection details
- NAT Gateway IDs
- SSH connection commands

## 💰 Cost Optimization

### Free Tier Eligible Resources
- **EC2 Instances**: t3.micro (750 hours/month)
- **EBS Storage**: 30 GB General Purpose SSD
- **Data Transfer**: 15 GB outbound per month

### Cost Considerations
- **NAT Gateway**: ~$45/month per gateway (2 gateways = ~$90/month)
- **Elastic IPs**: Free when attached to running instances
- **Alternative**: Use NAT instances for cheaper setup (set `enable_nat_gateway = false`)

### Cost-Saving Options
```hcl
# Use NAT instances instead of NAT Gateways
enable_nat_gateway = false

# Deploy to public subnets for development
deploy_to_private = false

# Disable bastion EIP if not needed
enable_bastion_eip = false
```

## 🏗️ Advanced Configurations

### High Availability Setup
```hcl
# Deploy across multiple AZs
availability_zone_1 = "us-west-2a"
availability_zone_2 = "us-west-2b"

# Enable NAT Gateways for redundancy
enable_nat_gateway = true

# Deploy applications to private subnets
deploy_to_private = true
```

### Development Setup
```hcl
# Single AZ for cost savings
enable_nat_gateway = false
deploy_to_private = false
enable_bastion_eip = false
```

## 🔍 Verification

### Resource Map Screenshot
After deployment, verify the infrastructure:
1. Go to AWS Console → VPC → Your VPCs
2. Select your VPC (`<project-name>-vpc`)
3. Click on "Resource map" tab
4. Take a screenshot showing all resources

### Connectivity Tests
```bash
# Test bastion connectivity
ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-ip>

# Test private instance connectivity (if deployed)
ssh -i ~/.ssh/your-key.pem -J ec2-user@<bastion-ip> ec2-user@<private-ip>

# Test internet connectivity from private instance
curl -I https://google.com
```

## 🚀 CI/CD Integration

### GitHub Actions
The repository includes GitHub Actions workflow for:
- Terraform validation
- Security scanning
- Automated deployment
- Infrastructure testing

### Workflow Features
- **Terraform Plan**: On pull requests
- **Terraform Apply**: On main branch push
- **Security Scanning**: Checkov integration
- **Cost Estimation**: Infracost integration

## 🐛 Troubleshooting

### Common Issues

1. **Key Pair Not Found**
   ```
   Error: InvalidKeyPair.NotFound
   Solution: Create key pair in AWS EC2 console or via CLI
   ```

2. **Insufficient Permissions**
   ```
   Error: UnauthorizedOperation
   Solution: Ensure AWS credentials have VPC, EC2, and IAM permissions
   ```

3. **Availability Zone Not Available**
   ```
   Error: InvalidSubnet.AvailabilityZone
   Solution: Check available AZs in your region and update variables
   ```

### Debug Commands
```bash
# Check Terraform state
terraform show

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check

# Destroy resources (be careful!)
terraform destroy
```

## 📚 Additional Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Kubernetes Networking Concepts](https://kubernetes.io/docs/concepts/cluster-administration/networking/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For questions and support:
- Create an issue in this repository
- Contact the development team
- Check the troubleshooting section above

---

**Note**: This infrastructure is designed for learning and development purposes. For production use, consider additional security measures, monitoring, and compliance requirements.
# AWS DevOps Infrastructure with Terraform

A simple, **AWS Free Tier friendly** Terraform setup for learning DevOps fundamentals.

## 🎯 What This Creates

- **1 EC2 instance** (t2.micro - Free Tier eligible)
- **1 S3 bucket** for application data
- **VPC with public subnet** for networking
- **Security group** with basic web and SSH access

## 🏗️ Architecture

```
Internet
    ↓
Internet Gateway
    ↓
VPC (10.0.0.0/16)
    ↓
Public Subnet (10.0.1.0/24)
    ↓
[EC2 Instance] ← Security Group (firewall rules)
    |
S3 Bucket
```

## 📁 Project Structure

```
aws-devops/
├── main.tf              # Main infrastructure using modules
├── variables.tf         # Variable definitions
├── terraform.tfvars     # Variable values (customize this!)
├── outputs.tf           # Output definitions
├── provider.tf          # AWS provider configuration
├── backend.tf           # State management (commented out)
├── modules/             # Reusable modules
│   ├── networking/      # VPC, subnets, security groups
│   ├── compute/         # EC2 instances
│   └── storage/         # S3 buckets
└── README.md           # This file
```

## 🚀 Quick Start

### Prerequisites

1. **AWS Account** with Free Tier available
2. **AWS CLI** configured with your credentials
3. **Terraform** installed (>= 1.0.0)

### Setup Steps

1. **Clone and customize**:
   ```bash
   git clone <your-repo>
   cd aws-devops
   ```

2. **Edit `terraform.tfvars`**:
   ```hcl
   # IMPORTANT: Change these values!
   app_bucket_name = "your-unique-bucket-name-123"
   ssh_cidr_blocks = ["YOUR_IP/32"]  # Your IP for security
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review the plan**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

6. **Get outputs**:
   ```bash
   terraform output
   ```

## 🌐 Networking Module Deep Dive

### Architecture Diagram

```
Internet
    ↓
Internet Gateway
    ↓
VPC (10.0.0.0/16)
    ↓
Public Subnet (10.0.1.0/24)
    ↓
EC2 Instance
    ↓
Security Group (Firewall)
```

### CIDR Block Calculations

**CIDR (Classless Inter-Domain Routing)** defines IP address ranges:

| CIDR | Available IPs | Range Example | Use Case |
|------|---------------|---------------|----------|
| `/16` | 65,536 | 10.0.0.0 - 10.0.255.255 | Large VPC |
| `/24` | 256 | 10.0.1.0 - 10.0.1.255 | Single subnet |
| `/32` | 1 | 10.0.1.100 | Single host |

**Calculation Formula:** `2^(32-prefix) = available IPs`
- `/16`: 2^(32-16) = 2^16 = 65,536 IPs
- `/24`: 2^(32-24) = 2^8 = 256 IPs

### Resource Creation Flow

1. **VPC Creation**:
   ```hcl
   resource "aws_vpc" "main" {
     cidr_block = var.vpc_cidr  # Input: "10.0.0.0/16"
   }
   # AWS assigns: vpc_id = "vpc-0123456789abcdef0"
   ```

2. **Resource Naming Pattern**:
   ```hcl
   resource "RESOURCE_TYPE" "LOCAL_NAME" {
     # configuration
   }
   # Reference as: RESOURCE_TYPE.LOCAL_NAME.ATTRIBUTE
   ```

3. **VPC ID Usage vs CIDR Block**:
   ```hcl
   resource "aws_subnet" "public" {
     vpc_id     = aws_vpc.main.id        # ATTACHMENT: Links subnet to VPC
     cidr_block = var.public_subnet_cidr # IP RANGE: Sets subnet's IP addresses
   }
   ```
   
   **Key Difference:**
   - **`vpc_id = aws_vpc.main.id`** → **ATTACHMENT** (which VPC to attach to)
   - **`cidr_block = "10.0.1.0/24"`** → **IP RANGE** (what IP addresses to use)

### Network Components Explained

#### VPC (Virtual Private Cloud)
- **Purpose**: Your isolated network in AWS
- **CIDR**: `10.0.0.0/16` (65,536 IP addresses)
- **Function**: Container for all networking resources

#### Public Subnet
- **Purpose**: Network segment with internet access
- **CIDR**: `10.0.1.0/24` (256 IP addresses)
- **Key Setting**: `map_public_ip_on_launch = true`
- **Function**: Where internet-facing resources live

#### Private Subnet (Not Used)
- **Purpose**: Network segment without direct internet access
- **Use Case**: Databases, internal services
- **Access**: Through NAT Gateway or VPN

#### Internet Gateway
- **Purpose**: Door between VPC and internet
- **Function**: Enables internet connectivity
- **Attachment**: One per VPC

#### Route Table
- **Purpose**: Traffic routing rules
- **Key Route**: `0.0.0.0/0 → Internet Gateway`
- **Meaning**: "Send all internet traffic through IGW"

#### Security Group
- **Purpose**: Virtual firewall for EC2 instances
- **Level**: Instance-level (not subnet-level)
- **Rules**: Ingress (inbound) and Egress (outbound)

### Variable Types and Usage

#### Two Types of Configuration Lines

**1. CIDR Block Lines (IP Range Configuration)**
```hcl
# YOU define the IP address ranges
cidr_block = "10.0.0.0/16"    # VPC gets this IP range
cidr_block = "10.0.1.0/24"    # Subnet gets this smaller IP range
cidr_block = "0.0.0.0/0"      # Route table: "all internet destinations"
```

**2. Resource ID Lines (Attachment/Relationship)**
```hcl
# AWS-assigned IDs for linking resources together
vpc_id     = aws_vpc.main.id          # "Attach subnet TO this VPC"
gateway_id = aws_internet_gateway.main.id  # "Route traffic THROUGH this gateway"
subnet_id  = aws_subnet.public.id     # "Place EC2 IN this subnet"
```

#### Purpose Comparison
| Line Type | Purpose | Example | Meaning |
|-----------|---------|---------|---------|
| `cidr_block =` | **IP Range Setup** | `"10.0.1.0/24"` | "Use these IP addresses" |
| `vpc_id =` | **Resource Attachment** | `aws_vpc.main.id` | "Attach to this VPC" |
| `gateway_id =` | **Traffic Routing** | `aws_internet_gateway.main.id` | "Send traffic through this gateway" |
| `subnet_id =` | **Resource Placement** | `aws_subnet.public.id` | "Place resource in this subnet" |

### Networking Module Outputs and Usage

#### What the Networking Module Exports
```hcl
# modules/networking/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}
```

#### Where These Outputs Are Used

**1. In Root main.tf (Module Composition)**
```hcl
# Root main.tf - Compute module uses networking outputs
module "compute" {
  source = "./modules/compute"
  
  # Uses networking module outputs as inputs
  subnet_id         = module.networking.public_subnet_id     # Where to place EC2
  security_group_id = module.networking.security_group_id   # What firewall rules
  s3_bucket_arn     = module.storage.bucket_arn            # Which S3 bucket
}
```

**2. In Root outputs.tf (External Access)**
```hcl
# Root outputs.tf - Exposes networking info to users
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
```

#### Output Flow Diagram
```
Networking Module Creates:
├── VPC (vpc-abc123)
├── Subnet (subnet-def456)
└── Security Group (sg-ghi789)
        ↓
Networking Module Outputs:
├── vpc_id = "vpc-abc123"
├── public_subnet_id = "subnet-def456"
└── security_group_id = "sg-ghi789"
        ↓
Used By:
├── Compute Module (needs subnet_id, security_group_id)
├── Root Outputs (shows info to user)
└── Future Modules (monitoring, databases, etc.)
```

#### Why This Pattern Works
- **Loose Coupling**: Modules don't need to know internal details
- **Reusability**: Networking module can be used in different projects
- **Dependency Management**: Terraform automatically orders creation
- **Information Hiding**: Only essential IDs are exposed

### Security Group Rules

#### Current Configuration
```hcl
# HTTP - Web traffic
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Anyone on internet
}

# HTTPS - Secure web traffic
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Anyone on internet
}

# SSH - Remote access
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.ssh_cidr_blocks  # Configurable
}

# Outbound - All traffic allowed
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

#### Port Strategy
- **Ports 3000, 3001**: Internal-only (behind Caddy reverse proxy)
- **Ports 80, 443**: Public-facing (Caddy handles routing)
- **Port 22**: SSH access (should be restricted to your IP)

## 🔧 Customization

### Variables in `terraform.tfvars`

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Project name for resource naming | `aws-devops` |
| `aws_region` | AWS region | `us-west-2` |
| `instance_type` | EC2 instance type | `t2.micro` |
| `app_bucket_name` | S3 bucket name (must be unique!) | `aws-devops-app-bucket-unique-123` |
| `ssh_cidr_blocks` | IP addresses allowed SSH access | `["0.0.0.0/0"]` |

### Security Note

⚠️ **IMPORTANT**: Change `ssh_cidr_blocks` from `["0.0.0.0/0"]` to your specific IP address for security!

## 🗂️ State Management

Currently using **local state** (terraform.tfstate file). For production:

1. Uncomment the backend configuration in `backend.tf`
2. Create an S3 bucket and DynamoDB table
3. Update the bucket/table names
4. Run `terraform init` to migrate state

## 🧹 Cleanup

To avoid charges, destroy resources when done:

```bash
terraform destroy
```

## 📚 Learning Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)

## 🤝 Contributing

This is a learning project! Feel free to:
- Add more modules
- Improve security
- Add monitoring
- Create different environments

## 📝 Next Steps

Once comfortable with this setup:
1. Add monitoring with CloudWatch
2. Implement CI/CD pipelines
3. Add auto-scaling
4. Set up remote state management
5. Create multiple environments (dev/staging/prod)
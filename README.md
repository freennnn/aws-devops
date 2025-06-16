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

## 🔐 IAM Authentication: Users vs Roles

This project supports **two authentication approaches** for AWS access:

### 🏗️ **Authentication Architecture**

```
Root User (you)
├── IAM User Group (existing - for personal use)
│   └── IAM User (existing - for personal use)
│       └── Access Keys (permanent credentials)
│           └── AWS CLI uses these keys
└── OIDC Identity Provider (NEW - trusts GitHub)
    └── IAM Role "GithubActionsRole" (NEW - for automation)
        └── GitHub Actions assumes this role (temporary credentials)
```

### 🆚 **User vs Role Comparison**

| Aspect | IAM User (Personal) | IAM Role (GitHub Actions) |
|--------|-------------------|---------------------------|
| **Credentials** | Permanent access keys | Temporary tokens (1 hour) |
| **Storage** | Stored locally/GitHub secrets | No permanent storage needed |
| **Security Risk** | If leaked, works forever | If leaked, expires quickly |
| **Use Case** | Human access (CLI, Console) | Application/Service access |
| **Rotation** | Manual key rotation needed | Automatic token refresh |
| **Audit** | User actions logged | Role assumption logged |

### 🔑 **Approach 1: IAM User (Current Setup)**

**Best for**: Personal development, AWS CLI usage, learning

```bash
# Your current setup
aws configure
# Uses permanent access keys stored in ~/.aws/credentials
```

**GitHub Actions Configuration**:
```yaml
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Pros**:
- ✅ Simple to set up
- ✅ Works immediately
- ✅ Good for learning/development

**Cons**:
- ❌ Permanent credentials (security risk)
- ❌ Manual key rotation required
- ❌ Same keys used everywhere

### 🎭 **Approach 2: IAM Role (Recommended for Production)**

**Best for**: Production deployments, team collaboration, enhanced security

**GitHub Actions Configuration**:
```yaml
permissions:
  id-token: write   # Allow GitHub to get identity token
  contents: read

steps:
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::ACCOUNT:role/GithubActionsRole
    aws-region: eu-north-1
```

**Pros**:
- ✅ No permanent secrets in GitHub
- ✅ Automatic credential rotation (1-hour tokens)
- ✅ Enhanced security and audit trail
- ✅ Follows AWS best practices

**Cons**:
- ❌ More complex initial setup
- ❌ Requires understanding of OIDC/roles

### 🚀 **Setting Up IAM Role for GitHub Actions**

#### Step 1: Apply Terraform Configuration
```bash
# The github-actions-iam.tf file creates:
# - OIDC Identity Provider (trusts GitHub)
# - IAM Role with required permissions
# - Trust policy linking role to your repository

terraform apply
```

#### Step 2: Update GitHub Repository Settings

**Repository Variables** (Settings → Secrets and variables → Actions → Variables):
```
TF_VAR_PROJECT_NAME=rs-aws-devops
TF_VAR_AWS_REGION=eu-north-1
TF_VAR_APP_BUCKET_NAME=rs-aws-devops-app-bucket-freen
TF_VAR_KEY_NAME=rs-devops-key
TF_VAR_SSH_CIDR_BLOCKS=["0.0.0.0/0"]
TF_VAR_GITHUB_REPOSITORY=your-username/your-repo-name
```

#### Step 3: Remove Old Secrets (if using role approach)
- Remove `AWS_ACCESS_KEY_ID` from repository secrets
- Remove `AWS_SECRET_ACCESS_KEY` from repository secrets

### 🔄 **How Temporary Credentials Work**

#### Each GitHub Actions Run:
```
Workflow Starts
├── GitHub requests temporary token from AWS (1 hour validity)
├── Run terraform commands using temporary token
├── Token automatically refreshes if workflow runs > 1 hour
└── Workflow ends → Token expires and becomes useless
```

#### Multiple Runs Over Time:
```
Monday 9 AM: New workflow → Fresh 1-hour token → Deploy → Token expires
Tuesday 9 AM: New workflow → Fresh 1-hour token → Deploy → Token expires
Wednesday 9 AM: New workflow → Fresh 1-hour token → Deploy → Token expires
```

### 🛡️ **Security Benefits of Roles**

1. **No Permanent Secrets**: No long-term credentials stored in GitHub
2. **Automatic Expiration**: Tokens expire in 1 hour, limiting damage if compromised
3. **Audit Trail**: AWS CloudTrail logs when GitHub assumes the role
4. **Granular Control**: Role only works for your specific repository
5. **Principle of Least Privilege**: Role has only necessary permissions

### 🔧 **Choosing Your Approach**

#### Use **IAM User** if:
- 👨‍💻 Learning Terraform/AWS
- 🏠 Personal projects only
- 🚀 Want quick setup
- 📚 Focusing on infrastructure concepts

#### Use **IAM Role** if:
- 🏢 Production deployments
- 👥 Team collaboration
- 🔒 Security is a priority
- 📈 Scaling beyond personal use

### 📋 **Migration Path**

**Phase 1**: Start with IAM User (simple, works immediately)
**Phase 2**: Learn the concepts, get comfortable with Terraform
**Phase 3**: Migrate to IAM Role (enhanced security, production-ready)

Both approaches are valid and can coexist. Your personal AWS CLI can use IAM User credentials while GitHub Actions uses the IAM Role.

### 🔄 **Migration from Access Keys to Role-Based Authentication**

#### 🥚🐔 **The Chicken-and-Egg Problem**

When migrating from IAM User to IAM Role, you face a bootstrap challenge:

- **To create the IAM role**: You need AWS credentials to run `terraform apply`
- **To remove access keys**: You need the role to be created first
- **But to create the role**: You need the access keys!

#### 📋 **Step-by-Step Migration Process**

**⚠️ Important**: Don't remove access keys until the role is working!

##### **Phase 1: Create the Role Infrastructure**

**Step 1: Apply Terraform (Uses Current Access Keys)**
```bash
# This creates the OIDC provider and IAM role
terraform apply
```

**Step 2: Get the Role ARN**
```bash
terraform output github_actions_role_arn
# Output: arn:aws:iam::123456789012:role/GithubActionsRole
```

**Step 3: Add Role ARN to GitHub Variables**
Go to GitHub → Settings → Secrets and variables → Actions → Variables:
```
GITHUB_ACTIONS_ROLE_ARN=arn:aws:iam::ACCOUNT:role/GithubActionsRole
```

##### **Phase 2: Update GitHub Actions Workflow**

**Step 4: Create Role-Based Workflow**
Update `.github/workflows/terraform.yml` to use role instead of access keys:

```yaml
# OLD - Access Key Based (remove this)
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

# NEW - Role Based (add this)
permissions:
  id-token: write   # Critical for OIDC
  contents: read

steps:
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ vars.GITHUB_ACTIONS_ROLE_ARN }}
    aws-region: eu-north-1
```

**Step 5: Test the New Authentication**
- Push a change to trigger the workflow
- Verify all jobs pass with role-based auth
- Check AWS CloudTrail for role assumption logs

##### **Phase 3: Clean Up (Only After Testing)**

**Step 6: Remove Access Keys from GitHub**
Only after confirming role-based auth works:
- Delete `AWS_ACCESS_KEY_ID` from GitHub repository secrets
- Delete `AWS_SECRET_ACCESS_KEY` from GitHub repository secrets

#### 🛡️ **Why This Phased Approach?**

**Safety Reasons:**
1. **Terraform state is in S3** - need credentials to access remote state
2. **Role creation requires auth** - can't create role without existing credentials
3. **Rollback capability** - can revert if role auth fails
4. **Testing validation** - ensure role works before removing fallback

#### 🔍 **What Gets Created by `github-actions-iam.tf`**

**1. OIDC Identity Provider**
```hcl
# Tells AWS: "Trust tokens from GitHub Actions"
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
  # GitHub's SSL certificate thumbprints for security
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
```

**2. IAM Role with Trust Policy**
```hcl
# Role that GitHub Actions can "become"
resource "aws_iam_role" "github_actions" {
  name = "GithubActionsRole"
  # Trust policy: Only YOUR repository can assume this role
  assume_role_policy = {
    Condition = {
      StringLike = {
        "token.actions.githubusercontent.com:sub" = "repo:freen/rs-aws-devops:*"
      }
    }
  }
}
```

**3. AWS Managed Policy Attachments**
- `AmazonEC2FullAccess` - Manage EC2 instances
- `AmazonRoute53FullAccess` - DNS management
- `AmazonS3FullAccess` - S3 bucket operations
- `IAMFullAccess` - IAM role/policy management
- `AmazonVPCFullAccess` - Network infrastructure
- `AmazonSQSFullAccess` - Queue services
- `AmazonEventBridgeFullAccess` - Event management

#### 🔄 **How Role-Based Authentication Works**

**Each GitHub Actions Run:**
```
1. Workflow starts
2. GitHub generates OIDC token (contains repo info)
3. GitHub sends token to AWS STS
4. AWS validates token against OIDC provider
5. AWS checks trust policy (is this the right repo?)
6. AWS issues temporary credentials (1 hour)
7. Workflow runs with temporary credentials
8. Credentials expire when workflow ends
```

**Security Benefits:**
- ✅ **No permanent secrets** stored in GitHub
- ✅ **Automatic credential rotation** (1-hour tokens)
- ✅ **Repository-specific access** (only your repo can use the role)
- ✅ **Audit trail** (AWS CloudTrail logs role assumptions)
- ✅ **Principle of least privilege** (role has only necessary permissions)

#### 🚨 **Troubleshooting Role-Based Auth**

**Common Issues:**

1. **"No permission to assume role"**
   - Check `github_repository` variable matches your actual repo
   - Verify OIDC provider is created
   - Ensure trust policy conditions are correct

2. **"Invalid identity token"**
   - Add `permissions: id-token: write` to workflow
   - Check GitHub repository settings allow OIDC

3. **"Role not found"**
   - Verify role ARN is correct in GitHub variables
   - Ensure `terraform apply` completed successfully

**Debug Steps:**
```bash
# Check if role exists
aws iam get-role --role-name GithubActionsRole

# Check role ARN
terraform output github_actions_role_arn

# Validate OIDC provider
aws iam list-open-id-connect-providers
```

#### 📊 **Comparison: Before vs After Migration**

| Aspect | Access Keys (Before) | IAM Role (After) |
|--------|---------------------|------------------|
| **Credentials** | Permanent (never expire) | Temporary (1 hour) |
| **Storage** | GitHub secrets | No storage needed |
| **Security Risk** | High (if leaked, permanent access) | Low (tokens expire quickly) |
| **Rotation** | Manual (you must rotate) | Automatic (AWS handles it) |
| **Audit** | User actions logged | Role assumption + actions logged |
| **Repository Scope** | Can be used anywhere | Only your specific repository |
| **Setup Complexity** | Simple | More complex initially |
| **Production Ready** | Not recommended | AWS best practice |

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
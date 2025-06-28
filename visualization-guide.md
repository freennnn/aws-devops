# AWS Infrastructure Visualization Guide

## After Terraform Deployment - Getting Resource Maps

### Method 1: AWS Console VPC Resource Map
1. **Navigate to AWS Console**
   - Go to VPC service
   - Select your VPC: `rs-aws-devops-vpc`
   - Click "Resource map" tab
   - Take screenshot of the visual diagram

2. **What you'll see:**
   ```
   ┌─────────────────────────────────────────────────────────────┐
   │                    VPC (10.0.0.0/16)                       │
   │  ┌─────────────────┐              ┌─────────────────┐      │
   │  │  Public Subnet  │              │  Public Subnet  │      │
   │  │   10.0.1.0/24   │              │   10.0.2.0/24   │      │
   │  │   (AZ-1a)       │              │   (AZ-1b)       │      │
   │  └─────────────────┘              └─────────────────┘      │
   │  ┌─────────────────┐              ┌─────────────────┐      │
   │  │ Private Subnet  │              │ Private Subnet  │      │
   │  │   10.0.3.0/24   │              │   10.0.4.0/24   │      │
   │  │   (AZ-1a)       │              │   (AZ-1b)       │      │
   │  └─────────────────┘              └─────────────────┘      │
   └─────────────────────────────────────────────────────────────┘
   ```

### Method 2: AWS Systems Manager - Inventory
1. **Go to Systems Manager → Inventory**
2. **View EC2 instances and their relationships**
3. **Network topology view**

### Method 3: AWS Config - Resource Relationships
1. **Go to AWS Config**
2. **Select any resource (VPC, EC2, etc.)**
3. **View "Resource relationships" diagram**
4. **Screenshot the relationship map**

### Method 4: Terraform Graph Visualization
```bash
# Generate Terraform dependency graph
terraform graph | dot -Tpng > infrastructure-graph.png

# Or use terraform-visual for better diagrams
pip install terraform-visual
terraform-visual --file infrastructure-visual.png
```

### Method 5: AWS Application Composer
1. **Go to AWS Console → Application Composer**
2. **Import existing resources**
3. **Generate visual architecture diagram**
4. **Export as image**

### Method 6: Third-party Tools

#### A. AWS Perspective (Free)
```bash
# Install AWS Perspective
npm install -g aws-perspective-cli
aws-perspective deploy
# Access web interface for visual diagrams
```

#### B. Lucidchart AWS Architecture Import
1. **Use Lucidchart AWS import feature**
2. **Connect to your AWS account**
3. **Auto-generate architecture diagrams**

#### C. CloudCraft (Paid)
1. **Connect CloudCraft to AWS**
2. **Auto-discover resources**
3. **Generate beautiful 3D diagrams**

### Method 7: AWS CLI + Visualization Scripts

#### Get Resource Information:
```bash
# List all VPC resources
aws ec2 describe-vpcs --vpc-ids $(terraform output -raw vpc_id)

# Get subnet information
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Get security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Get NAT Gateways
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$(terraform output -raw vpc_id)"
```

### Method 8: Custom Terraform Output for Visualization

Add to your `outputs.tf`:
```hcl
output "infrastructure_summary" {
  description = "Summary of deployed infrastructure for visualization"
  value = {
    vpc = {
      id   = module.networking.vpc_id
      cidr = var.vpc_cidr
    }
    public_subnets = {
      subnet_1 = {
        id   = module.networking.public_subnet_1_id
        cidr = var.public_subnet_1_cidr
        az   = var.availability_zone_1
      }
      subnet_2 = {
        id   = module.networking.public_subnet_2_id
        cidr = var.public_subnet_2_cidr
        az   = var.availability_zone_2
      }
    }
    private_subnets = {
      subnet_1 = {
        id   = module.networking.private_subnet_1_id
        cidr = var.private_subnet_1_cidr
        az   = var.availability_zone_1
      }
      subnet_2 = {
        id   = module.networking.private_subnet_2_id
        cidr = var.private_subnet_2_cidr
        az   = var.availability_zone_2
      }
    }
    nat_gateways = module.networking.nat_gateway_ids
    bastion = {
      id        = module.bastion.instance_id
      public_ip = module.bastion.public_ip
    }
    web_server = {
      id         = module.compute.instance_id
      private_ip = module.compute.instance_private_ip
    }
  }
}
```

## Best Screenshots to Take:

### 1. VPC Resource Map (Most Important)
- **Location**: VPC Console → Your VPC → Resource map
- **Shows**: Complete network topology

### 2. EC2 Instance Network View
- **Location**: EC2 Console → Instances → Network tab
- **Shows**: Instance placement and connectivity

### 3. Security Groups Visualization
- **Location**: EC2 Console → Security Groups → Inbound/Outbound rules
- **Shows**: Traffic flow rules

### 4. Route Tables
- **Location**: VPC Console → Route Tables
- **Shows**: Traffic routing configuration

### 5. NAT Gateway Status
- **Location**: VPC Console → NAT Gateways
- **Shows**: Internet connectivity setup

## Pro Tips for Better Screenshots:

1. **Use browser zoom** to fit entire diagram
2. **Enable browser developer tools** for clean screenshots
3. **Use AWS Console's export features** when available
4. **Combine multiple views** for complete picture
5. **Add annotations** to explain components

## After Taking Screenshots:

1. **Document the architecture** with labels
2. **Create a presentation** showing before/after
3. **Share with team** for review
4. **Update documentation** with current state
5. **Save for troubleshooting** reference 